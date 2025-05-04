from .accessor import Accessor
from .expr import Expr
from .sysconfig import SymConfig


trait CasparElement(Movable & Copyable):
    fn __add__(self, other: Self) -> Self:
        ...


@value
struct Storage[T: CasparElement, size: Int](Movable & Copyable):
    alias Data = InlineArray[T, size, run_destructors=True]
    var data: Self.Data

    fn __init__(out self, owned *args: T):
        self.data = Self.Data(storage=args^)

    fn __init__(out self, *, uninitialized: Bool):
        self.data = Self.Data(uninitialized=uninitialized)

    fn __init__(out self, owned storage: VariadicListMem[T, _]):
        self.data = Self.Data(storage=storage^)

    fn __getitem__(ref self, idx: Int) -> ref [self.data] T:
        return self.data[idx]

    fn init_unsafe(mut self, idx: Int, owned value: T):
        """Set the value at the given index without bound checking
        and without running destructor of existing value."""
        self.data.unsafe_ptr().offset(idx).init_pointee_move(value^)


trait Storable(Movable & Copyable):
    alias elemT: CasparElement
    alias size: Int

    fn to_storage(self) -> Storage[elemT, size]:
        ...

    @staticmethod
    fn from_storage(owned storage: Storage[elemT, size]) -> Self:
        ...


@value
struct Vec[elemT_: CasparElement, size_: Int](Storable):
    alias elemT = elemT_
    alias size = size_

    alias Storage = Storage[Self.elemT, Self.size]
    var storage: Self.Storage

    fn __init__(out self, owned *args: elemT_):
        debug_assert(len(args) == Self.size, "Invalid number of arguments")
        self.storage = Self.Storage(storage=args^)

    @staticmethod
    fn from_storage(owned storage: Self.Storage) -> Self:
        return Self(storage=storage)

    fn to_storage(self) -> Self.Storage:
        return self.storage

    fn __add__(self, other: Self) -> Self:
        var storage = Self.Storage(uninitialized=True)
        for i in range(0, self.storage.size):
            storage.init_unsafe(i, self.storage[i] + other.storage[i])
        return Self(storage=storage^)

    fn __getitem__(ref self, idx: Int) -> ref [self.storage.data] Self.elemT:
        return self.storage[idx]
