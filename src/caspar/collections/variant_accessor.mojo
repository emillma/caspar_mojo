from caspar.funcs import Callable
from os import abort
from sys import alignof, sizeof
from sys.intrinsics import _type_is_eq
from caspar.accessors import Accessor
from memory import UnsafePointer
from caspar.sysconfig import SymConfig


struct AccessorVariant[sym: SymConfig](Copyable, Movable):
    alias Trait = Accessor
    alias _sentinel: Int = -1
    var _impl: __mlir_type[
        `!kgen.variant<[rebind(:`,
        __type_of(sym.access_types),
        ` `,
        sym.access_types,
        `)]>`,
    ]

    fn __init__(out self, *, unsafe_uninitialized: Bool):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self._impl))

    @implicit
    fn __init__[T: Self.Trait](out self, owned value: T):
        alias idx = Self.type_idx_of[T]()
        self = Self(unsafe_uninitialized=True)
        self.type_idx() = idx
        self._get_ptr[T]().init_pointee_move(value^)

    fn copy(self, out copy: Self):
        copy = Self(unsafe_uninitialized=True)
        copy.type_idx() = self.type_idx()

        @parameter
        for i in range(len(VariadicList(sym.access_types))):
            alias T = sym.access_types[i]
            if copy.type_idx() == i:
                copy._get_ptr[T]().init_pointee_move(self._get_ptr[T]()[])
                return

    fn __copyinit__(out self, other: Self):
        self = other.copy()

    fn __moveinit__(out self, owned other: Self):
        self = Self(unsafe_uninitialized=True)
        self.type_idx() = other.type_idx()

        @parameter
        for i in range(len(VariadicList(sym.access_types))):
            alias T = sym.access_types[i]
            if self.type_idx() == i:
                # Calls the correct __moveinit__
                other._get_ptr[T]().move_pointee_into(self._get_ptr[T]())
                return

    fn __del__(owned self):
        """Destroy the variant."""

        @parameter
        for i in range(len(VariadicList(sym.access_types))):
            if self.type_idx() == i:
                self._get_ptr[sym.access_types[i]]().destroy_pointee()
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
        alias idx = Self.sym.access_idx[T]()
        return self.type_idx() == idx

    fn unsafe_get[T: Self.Trait](ref self) -> ref [self] T:
        debug_assert(self.isa[T](), "get: wrong variant type")
        return self._get_ptr[T]()[]

    @staticmethod
    fn type_idx_of[T: Self.Trait]() -> Int:
        return sym.access_idx[T]()
