# from .accessor import Accessor
from .expr import Expr
from .sysconfig import SymConfig
from memory import UnsafePointer


trait CasparElement(Movable & Copyable & Writable):
    fn __add__(self, other: Self) -> Self:
        ...


@value
struct Storage[T: CasparElement, size: Int](Movable & Copyable):
    # alias Data = __mlir_type[`!pop.array<`, size.value, `, `, T, `>`]
    var _array: __mlir_type[`!pop.array<`, size.value, `, `, T, `>`]

    # fn __init__(out self, owned *args: T):
    #     self.data = Self.Data(storage=args^)

    fn __init__(out self, *, uninitialized: Bool):
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._array)
        )
        # self.data = Self.Data(uninitialized=uninitialized)

    fn __init__(out self, owned storage: VariadicListMem[T, _]):
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self._array)
        )
        for i in range(0, Self.size):
            self.init_unsafe(i, storage[i])
        __disable_del storage

    fn __getitem__(ref self, idx: Int) -> ref [self] T:
        return self.unsafe_ptr().offset(idx)[]

    fn __len__(self) -> Int:
        return self.size

    fn init_unsafe(mut self, idx: Int, owned value: T):
        """Set the value at the given index without bound checking
        and without running destructor of existing value."""
        self.unsafe_ptr().offset(idx).init_pointee_move(value^)

    @always_inline
    fn unsafe_ptr(
        ref self,
    ) -> UnsafePointer[
        T, mut = Origin(__origin_of(self)).mut, origin = __origin_of(self)
    ]:
        return (
            UnsafePointer(to=self._array)
            .bitcast[T]()
            .origin_cast[origin = __origin_of(self)]()
        )


trait Storable(Movable & Copyable):
    alias elemT: CasparElement
    alias size: Int

    fn to_storage(self) -> Storage[Self.elemT, Self.size]:
        ...

    @staticmethod
    fn from_storage(owned storage: Storage[elemT, size]) -> Self:
        ...


@value
struct Vec[elemT_: CasparElement, size_: Int](Storable):
    alias size = size_
    alias elemT = elemT_

    alias Storage = Storage[Self.elemT, Self.size]
    var storage: Self.Storage

    fn __init__(out self, owned *args: elemT_):
        debug_assert(len(args) == Self.size, "Invalid number of arguments")
        self.storage = Self.Storage(storage=args^)

    @staticmethod
    fn from_storage(owned storage: Self.Storage) -> Self:
        return Self(storage=storage)

    fn to_storage(self) -> Storage[Self.elemT, Self.size]:
        return self.storage

    # return self.storage

    # return self.storage

    # fn __add__(self, other: Self) -> Self:
    #     var storage = Self.Storage(uninitialized=True)
    #     for i in range(0, self.storage.size):
    #         storage.init_unsafe(i, self.storage[i] + other.storage[i])
    #     return Self(storage=storage^)

    # fn __getitem__(ref self, idx: Int) -> ref [self.storage.data] Self.elemT:
    #     return self.storage[idx]
