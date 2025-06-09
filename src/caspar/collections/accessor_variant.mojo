from caspar.funcs import Callable
from os import abort
from sys import alignof, sizeof
from sys.intrinsics import _type_is_eq

from memory import UnsafePointer
from caspar.accessors import Accessor
from builtin.range import _ZeroStartingRange


struct AccessorVariant[*Ts: Accessor]:
    alias Trait = Accessor
    alias range = range(len(VariadicList(Ts)))
    alias _sentinel: Int = -1
    var is_read: Bool
    var _impl: __mlir_type[`!kgen.variant<[rebind(:`, __type_of(Ts), ` `, Ts, `)]>`]

    fn __init__(out self, is_read: Bool, *, unsafe_uninitialized: Bool):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self._impl))
        self.is_read = is_read

    @implicit
    fn __init__[T: Accessor](out self, owned value: T):
        alias idx = Self.type_idx_of[T]()
        self = Self(T.is_read, unsafe_uninitialized=True)
        self.type_idx() = idx
        self._get_ptr[T]().init_pointee_move(value^)

    fn copy(self, out copy: Self):
        copy = Self(self.is_read, unsafe_uninitialized=True)
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
        self = Self(other.is_read, unsafe_uninitialized=True)
        self.type_idx() = other.type_idx()

        @parameter
        for i in Self.range:
            alias T = Ts[i]
            if self.type_idx() == i:
                # Calls the correct __moveinit__
                other._get_ptr[T]().move_pointee_into(self._get_ptr[T]())
                return

    fn do[func: fn[T: Accessor] (val: T) capturing](self):
        @parameter
        for i in Self.range:
            if i == Int(self.type_idx()):
                func(self.unsafe_get[Ts[i]]())
                return

    fn __del__(owned self):
        """Destroy the variant."""

        @parameter
        for i in Self.range:
            if self.type_idx() == i:
                self._get_ptr[Ts[i]]().destroy_pointee()
                return

    fn __getitem__[T: Self.Trait](ref self) -> ref [self] T:
        if not self.isa[T]():
            abort("get: wrong variant type")

        return self.unsafe_get[T]()

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

    fn unsafe_get[T: Self.Trait](ref self) -> ref [self] T:
        debug_assert(self.isa[T](), "get: wrong variant type")
        return self._get_ptr[T]()[]

    @staticmethod
    fn type_idx_of[T: Self.Trait]() -> Int:
        @parameter
        for i in Self.range:
            if _type_is_eq[Ts[i], T]():
                return i
        debug_assert(False, "type_idx_of: type not found in access_types")
        return Self._sentinel
