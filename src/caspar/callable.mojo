from memory import UnsafePointer
from sys import sizeof
from sys.intrinsics import _type_is_eq
from os import abort
from .expr import Expr, Call
from .sysconfig import SysConfig


trait Callable(CollectionElementNew):
    fn n_args(self) -> Int:
        ...

    fn n_outs(self) -> Int:
        ...

    fn write_call[sys: SysConfig, W: Writer](self, call: Call[sys], mut writer: W):
        ...


@value
struct CallableVariant[sys: SysConfig]:
    alias _mlir_type = __mlir_type[
        `!kgen.variant<[rebind(:`, __type_of(sys.FuncTs), ` `, sys.FuncTs, `)]>`
    ]
    var _impl: Self._mlir_type

    fn write_call[W: Writer](self, call: Call[sys], mut writer: W):
        @parameter
        for i in range(len(sys.FuncList)):
            if self.isa[sys.FuncTs[i]]():
                return self.unsafe_get[sys.FuncTs[i]]().write_call(call, writer)

    fn n_args(self) -> Int:
        @parameter
        for i in range(len(sys.FuncList)):
            alias T = sys.FuncTs[i]
            if self.isa[sys.FuncTs[i]]():
                return self.unsafe_get[T]().n_args()
        return -1

    fn n_outs(self) -> Int:
        @parameter
        for i in range(len(sys.FuncList)):
            if self.isa[sys.FuncTs[i]]():
                return self.unsafe_get[sys.FuncTs[i]]().n_outs()
        return -1

    @implicit
    fn __init__[T: Callable](out self, owned value: T):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self._get_type_index() = self._type_index_of[T]()
        self._get_ptr[T]().init_pointee_move(value^)

    fn __copyinit__(out self, other: Self):
        self._impl = other._impl

    fn _get_ptr[T: Callable](self) -> UnsafePointer[T]:
        alias idx = Self._type_index_of[T]()
        return __mlir_op.`pop.variant.bitcast`[
            _type = UnsafePointer[T]._mlir_type, index = idx.value
        ](UnsafePointer(to=self._impl).address)

    @always_inline("nodebug")
    fn _get_type_index(ref self) -> ref [self] UInt8:
        var discr_ptr = __mlir_op.`pop.variant.discr_gep`[
            _type = __mlir_type.`!kgen.pointer<scalar<ui8>>`
        ](UnsafePointer(to=self._impl).address)
        return UnsafePointer(discr_ptr).bitcast[UInt8]()[]

    @staticmethod
    fn _type_index_of[T: Callable]() -> Int:
        @parameter
        for i in range(len(VariadicList(sys.FuncTs))):

            @parameter
            if _type_is_eq[sys.FuncTs[i], T]():
                return i
        abort("Not initialized")
        return -1

    fn isa[T: Callable](self) -> Bool:
        alias idx = Self._type_index_of[T]()
        return self._get_type_index() == idx

    fn __getitem__[T: Callable](self) -> ref [self] T:
        if not self.isa[T]():
            abort("get: wrong variant type")
        return self._get_ptr[T]()[]

    fn unsafe_get[T: Callable](ref self) -> ref [self] T:
        debug_assert(self.isa[T](), "get: wrong variant type")
        return self._get_ptr[T]()[]
