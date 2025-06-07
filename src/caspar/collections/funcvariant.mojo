from caspar.funcs import Callable
from os import abort
from sys import alignof, sizeof
from sys.intrinsics import _type_is_eq

from memory import UnsafePointer


struct FuncVariant[*Ts: Callable](Copyable, Movable, ExplicitlyCopyable, KeyElement):
    # Fields
    alias _sentinel: Int = -1
    var hash: UInt
    var _impl: __mlir_type[`!kgen.variant<[rebind(:`, __type_of(Ts), ` `, Ts, `)]>`]

    fn __init__(out self, hashval: UInt, *, unsafe_uninitialized: Bool):
        self.hash = hashval
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self._impl))

    @implicit
    fn __init__[T: Callable](out self, owned value: T):
        alias idx = Self.type_idx_of[T]()
        self = Self(hash(value), unsafe_uninitialized=True)
        self.type_idx() = idx
        self._get_ptr[T]().init_pointee_move(value^)

    fn copy(self, out copy: Self):
        copy = Self(self.hash, unsafe_uninitialized=True)
        copy.type_idx() = self.type_idx()

        @parameter
        for i in range(len(VariadicList(Ts))):
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
        for i in range(len(VariadicList(Ts))):
            alias T = Ts[i]
            if self.type_idx() == i:
                # Calls the correct __moveinit__
                other._get_ptr[T]().move_pointee_into(self._get_ptr[T]())
                return

    fn __del__(owned self):
        """Destroy the variant."""

        @parameter
        for i in range(len(VariadicList(Ts))):
            if self.type_idx() == i:
                self._get_ptr[Ts[i]]().destroy_pointee()
                return

    fn __getitem__[T: Callable](ref self) -> ref [self] T:
        if not self.isa[T]():
            abort("get: wrong variant type")

        return self.unsafe_get[T]()

    @always_inline("nodebug")
    fn _get_ptr[T: Callable](self) -> UnsafePointer[T]:
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

    @always_inline
    fn take[T: Callable](mut self) -> T:
        if not self.isa[T]():
            abort("taking the wrong type!")

        return self.unsafe_take[T]()

    @always_inline
    fn unsafe_take[T: Callable](mut self) -> T:
        debug_assert(self.isa[T](), "taking wrong type")
        # don't call the variant's deleter later
        self.type_idx() = Self._sentinel
        return self._get_ptr[T]().take_pointee()

    @always_inline
    fn replace[Tin: Callable, Tout: Callable](mut self, owned value: Tin) -> Tout:
        if not self.isa[Tout]():
            abort("taking out the wrong type!")

        return self.unsafe_replace[Tin, Tout](value^)

    @always_inline
    fn unsafe_replace[
        Tin: Callable, Tout: Callable
    ](mut self, owned value: Tin) -> Tout:
        debug_assert(self.isa[Tout](), "taking out the wrong type!")

        var x = self.unsafe_take[Tout]()
        self.set[Tin](value^)
        return x^

    fn set[T: Callable](mut self, owned value: T):
        self = Self(value^)

    fn isa[T: Callable](self) -> Bool:
        alias idx = Self.type_idx_of[T]()
        return self.type_idx() == idx

    fn unsafe_get[T: Callable](ref self) -> ref [self] T:
        debug_assert(self.isa[T](), "get: wrong variant type")
        return self._get_ptr[T]()[]

    @staticmethod
    fn type_idx_of[T: Callable]() -> Int:
        @parameter
        for i in range(len(VariadicList(Ts))):
            if _type_is_eq[Ts[i], T]():
                return i
        return Self._sentinel

    @staticmethod
    fn supports[T: Callable]() -> Bool:
        return Self.type_idx_of[T]() != Self._sentinel

    fn __eq__(self, other: Self) -> Bool:
        if self.hash != other.hash or self.type_idx() != other.type_idx():
            return False

        @parameter
        for i in range(len(VariadicList(Ts))):
            if i == Int(self.type_idx()):
                alias T = self.Ts[i]
                return self.unsafe_get[T]() == other.unsafe_get[T]()
        return False

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return self.hash
