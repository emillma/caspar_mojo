from memory import UnsafePointer
from sys import sizeof
from sys.intrinsics import _type_is_eq
from os import abort
from .expr import Expr


trait Callable(CollectionElementNew):
    alias n_outs: Int
    alias n_args: Int

    fn repr(self, args: List[String]) -> String:
        ...


@value
struct Lookup[*Ts: Callable]:
    alias instanceT = CallableVariant[*Ts]
    var repr: fn (Self.instanceT, List[String]) -> String
    var n_args: Int
    var n_outs: Int

    @staticmethod
    fn of[T: Callable]() -> Self:
        fn repr(instance: Self.instanceT, args: List[String]) -> String:
            debug_assert(instance.isa[T](), "get: wrong variant type")
            debug_assert(len(args) == T.n_args, "Wrong number of args")
            return T.repr(instance[T], args)

        return Self(repr=repr, n_args=T.n_args, n_outs=T.n_outs)

    @staticmethod
    fn get_table() -> InlineArray[Self, len(VariadicList(Ts))]:
        var out = InlineArray[Self, len(VariadicList(Ts))](uninitialized=True)

        @parameter
        for i in range(len(VariadicList(Ts))):
            out[i] = Self.of[Ts[i]]()
        return out


@value
struct CallableVariant[*Ts: Callable]:
    alias table = Lookup[*Self.Ts].get_table()
    alias _mlir_type = __mlir_type[
        `!kgen.variant<[rebind(:`, __type_of(Ts), ` `, Ts, `)]>`
    ]
    var _impl: Self._mlir_type

    @implicit
    fn __init__[T: Callable](out self, owned value: T):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self._get_type_index() = self._type_index_of[T]()
        self._get_ptr[T]().init_pointee_move(value^)

    fn __copyinit__(out self, other: Self):
        self._impl = other._impl

    fn repr(self, args: List[String] = List[String]()) -> String:
        return Self.table[self._get_type_index()].repr(self, args)

    fn n_args(self) -> Int:
        return Self.table[self._get_type_index()].n_args

    fn n_outs(self) -> Int:
        return Self.table[self._get_type_index()].n_outs

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
        for i in range(len(VariadicList(Self.Ts))):

            @parameter
            if _type_is_eq[Ts[i], T]():
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
