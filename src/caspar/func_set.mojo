from sys.intrinsics import _type_is_eq
from memory import UnsafePointer
from os import abort

# from sys.terminate import exit

# from sys import alignof, sizeof


trait FuncT(CollectionElement):
    alias n_outs: Int
    alias n_args: Int


fn foo[T: AnyType, val: T]() -> T:
    return val


alias bar = __type_of(foo)


@value
struct FuncSet[*FuncTs: FuncT]:
    alias InnerT = FuncVariantInner[*FuncTs]

    var _func: Self.InnerT

    @implicit
    fn __init__[T: FuncT](out self, owned value: T):
        self._func = Self.InnerT(value^)

    @staticmethod
    fn make_table[
        resT: CollectionElement, //, func: fn[FuncT] () -> resT
    ]() -> InlineArray[resT, Self.n_funcsTs]:
        var table = InlineArray[resT, Self.n_funcsTs]()

        @parameter
        for i in range(Self.n_funcsTs):
            table[i] = func[Self.FuncTs[i]]()
        return table

    fn n_outs(self) -> Int:
        fn get_n_outs[T: FuncT]() -> Int:
            return T.n_outs

        alias table = Self.make_table[get_n_outs]()
        return table[self._func._get_discr()]


struct FuncVariantInner[*Ts: FuncT](
    CollectionElement,
    ExplicitlyCopyable,
):
    """Taken from utils.Variant struct."""

    # Fields
    alias _sentinel: Int = -1
    alias _mlir_type = __mlir_type[
        `!kgen.variant<[rebind(:`, __type_of(Ts), ` `, Ts, `)]>`
    ]
    var _impl: Self._mlir_type

    fn __init__(out self, *, unsafe_uninitialized: ()):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

    @implicit
    fn __init__[T: FuncT](out self, owned value: T):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        alias idx = Self._check[T]()
        self._get_discr() = idx
        self._get_ptr[T]().init_pointee_move(value^)

    fn copy(self, out copy: Self):
        copy = Self(unsafe_uninitialized=())
        copy._get_discr() = self._get_discr()

        @parameter
        for i in range(len(VariadicList(Ts))):
            alias T = Ts[i]
            if copy._get_discr() == i:
                copy._get_ptr[T]().init_pointee_move(self._get_ptr[T]()[])
                return

    fn __copyinit__(out self, other: Self):
        # Delegate to explicit copy initializer.
        self = other.copy()

    fn __moveinit__(out self, owned other: Self):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self._get_discr() = other._get_discr()

        @parameter
        for i in range(len(VariadicList(Ts))):
            alias T = Ts[i]
            if self._get_discr() == i:
                # Calls the correct __moveinit__
                other._get_ptr[T]().move_pointee_into(self._get_ptr[T]())
                return

    fn __del__(owned self):
        @parameter
        for i in range(len(VariadicList(Ts))):
            if self._get_discr() == i:
                self._get_ptr[Ts[i]]().destroy_pointee()
                return

    fn __getitem__[T: FuncT](ref self) -> ref [self] T:
        if not self.isa[T]():
            abort("get: wrong variant type")
        return self.unsafe_get[T]()

    @always_inline("nodebug")
    fn _get_ptr[T: FuncT](self) -> UnsafePointer[T]:
        alias idx = Self._check[T]()
        constrained[idx != Self._sentinel, "not a union element type"]()
        var ptr = UnsafePointer.address_of(self._impl).address
        var discr_ptr = __mlir_op.`pop.variant.bitcast`[
            _type = UnsafePointer[T]._mlir_type, index = idx.value
        ](ptr)
        return discr_ptr

    @always_inline("nodebug")
    fn _get_discr(ref self) -> ref [self] UInt8:
        var ptr = UnsafePointer.address_of(self._impl).address
        var discr_ptr = __mlir_op.`pop.variant.discr_gep`[
            _type = __mlir_type.`!kgen.pointer<scalar<ui8>>`
        ](ptr)
        return UnsafePointer(discr_ptr).bitcast[UInt8]()[]

    @always_inline
    fn take[T: FuncT](mut self) -> T:
        if not self.isa[T]():
            abort("taking the wrong type!")

        return self.unsafe_take[T]()

    @always_inline
    fn unsafe_take[T: FuncT](mut self) -> T:
        debug_assert(self.isa[T](), "taking wrong type")
        # don't call the variant's deleter later
        self._get_discr() = Self._sentinel
        return self._get_ptr[T]().take_pointee()

    # @always_inline
    # fn replace[
    #     Tin: FuncT, Tout: FuncT
    # ](mut self, owned value: Tin) -> Tout:
    #     if not self.isa[Tout]():
    #         abort("taking out the wrong type!")

    #     return self.unsafe_replace[Tin, Tout](value^)

    # @always_inline
    # fn unsafe_replace[
    #     Tin: CollectionElement, Tout: CollectionElement
    # ](mut self, owned value: Tin) -> Tout:
    #     debug_assert(self.isa[Tout](), "taking out the wrong type!")

    #     var x = self.unsafe_take[Tout]()
    #     self.set[Tin](value^)
    #     return x^

    # fn set[T: CollectionElement](mut self, owned value: T):
    #     self = Self(value^)

    fn isa[T: CollectionElement](self) -> Bool:
        alias idx = Self._check[T]()
        return self._get_discr() == idx

    fn unsafe_get[T: CollectionElement](ref self) -> ref [self] T:
        debug_assert(self.isa[T](), "get: wrong variant type")
        return self._get_ptr[T]()[]

    @staticmethod
    fn _check[T: CollectionElement]() -> Int:
        @parameter
        for i in range(len(VariadicList(Ts))):
            if _type_is_eq[Ts[i], T]():
                return i
        return Self._sentinel
