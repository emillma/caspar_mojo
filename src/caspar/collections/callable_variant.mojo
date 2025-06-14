from caspar.funcs import Callable
from os import abort
from sys import alignof, sizeof
from sys.intrinsics import _type_is_eq

from memory import UnsafePointer
from caspar.accessors import Accessor
from builtin.range import _ZeroStartingRange
from caspar.funcs import FuncInfo
from compile.reflection import get_type_name


struct CallableVariant[*Ts: Callable](Hashable):
    alias Trait = Callable
    alias _sentinel: Int = -1
    alias range = range(len(VariadicList(Ts)))

    var hash: UInt
    var _impl: __mlir_type[`!kgen.variant<[rebind(:`, __type_of(Ts), ` `, Ts, `)]>`]

    fn __init__(out self, hashval: UInt, *, unsafe_uninitialized: Bool):
        self.hash = hashval
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self._impl))

    @implicit
    fn __init__[T: Self.Trait](out self, owned value: T):
        alias idx = Self.type_idx_of[T]()
        self = Self(hash(value), unsafe_uninitialized=True)
        self.type_idx() = idx
        self._get_ptr[T]().init_pointee_move(value^)

    fn copy(self, out copy: Self):
        copy = Self(self.hash, unsafe_uninitialized=True)
        copy.type_idx() = self.type_idx()

        @parameter
        for i in Self.range:
            alias T = Ts[i]
            if copy.type_idx() == i:
                copy._get_ptr[T]().init_pointee_move(self._get_ptr[T]()[])
                return

    fn __copyinit__(out self, other: Self):
        self = other.copy()

    fn __moveinit__(out self, owned other: Self):
        self = Self(other.hash, unsafe_uninitialized=True)

        self.type_idx() = other.type_idx()

        @parameter
        for i in Self.range:
            alias T = Ts[i]
            if self.type_idx() == i:
                other._get_ptr[T]().move_pointee_into(self._get_ptr[T]())
                return

    fn do[func: fn[T: Callable] (val: T) capturing](self):
        @parameter
        for i in Self.range:
            if self.type_idx() == i:
                alias T = Ts[i]
                func(self[T])
                return

    fn __del__(owned self):
        """Destroy the variant."""

        @parameter
        for i in Self.range:
            if self.type_idx() == i:
                self._get_ptr[Ts[i]]().destroy_pointee()
                return

    fn __getitem__[T: Self.Trait, *, unsafe: Bool = False](ref self) -> ref [self] T:
        @parameter
        if not unsafe:
            if not self.isa[T]():
                abort("get: wrong variant type")
        alias name = get_type_name[T]()
        debug_assert(self.isa[T](), name + "!=" + String(self.type_idx()))
        return self._get_ptr[T]()[]

    @always_inline("nodebug")
    fn _get_ptr[T: Self.Trait](self) -> UnsafePointer[T]:
        alias idx = Self.type_idx_of[T]()
        constrained[idx != Self._sentinel, "not a union element type"]()
        var ptr = UnsafePointer(to=self._impl).address
        var discr_ptr = __mlir_op.`pop.variant.bitcast`[
            _type = UnsafePointer[T]._mlir_type, index = idx.value
        ](ptr)
        return discr_ptr

    @always_inline("nodebug")
    fn type_idx(ref self) -> ref [self] UInt8:
        var ptr = UnsafePointer(to=self._impl).address
        var discr_ptr = __mlir_op.`pop.variant.discr_gep`[
            _type = __mlir_type.`!kgen.pointer<scalar<ui8>>`
        ](ptr)
        return UnsafePointer(discr_ptr).bitcast[UInt8]()[]

    fn isa[T: Self.Trait](self) -> Bool:
        alias idx = Self.type_idx_of[T]()
        return self.type_idx() == idx

    @staticmethod
    fn type_idx_of[T: Self.Trait]() -> Int:
        @parameter
        for i in Self.range:
            if _type_is_eq[Ts[i], T]():
                return i
        debug_assert(False, "type_idx_of: type not found in access_types")
        return Self._sentinel

    fn info(self, out ret: FuncInfo):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(ret))

        @parameter
        fn inner[T: Self.Trait](func: T):
            ret = T.info

        self.do[inner]()

    fn __eq__(self, other: Self) -> Bool:
        if self.hash != other.hash or self.type_idx() != other.type_idx():
            return False

        @parameter
        for i in Self.range:
            if i == Int(self.type_idx()):
                alias T = Ts[i]
                return self[T, unsafe=True] == other[T, unsafe=True]
        return False

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return self.hash
