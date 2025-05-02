from .accessor import Accessor
from .expr import Expr
from .sysconfig import SymConfig


trait CasparElement(CollectionElement):
    fn __add__(self, other: Self) -> Self:
        ...


@value
struct Storage[T: CasparElement, size: Int](CollectionElement):
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

    fn set_unsafe(mut self, idx: Int, owned value: T):
        """Set the value at the given index without bound checking
        and running destructor of existing value."""
        self.data.unsafe_ptr().offset(idx).init_pointee_move(value^)


@value
struct Vec[T: CasparElement, size: Int]:
    alias Storage = Storage[T, size]
    var data: Self.Storage

    fn __init__(out self, owned *args: T):
        self.data = Self.Storage(storage=args^)

    @staticmethod
    fn from_storage(storage: Self.Storage) -> Self:
        return Self(storage)

    fn to_storage(self) -> ref [self.data] Self.Storage:
        return self.data

    fn __add__(self, other: Self) -> Self:
        var storage = Self.Storage(uninitialized=True)
        for i in range(0, self.data.size):
            storage.set_unsafe(i, self.data[i] + other.data[i])
        return Self(storage^)

    fn __getitem__(mut self, idx: Int) -> T:
        return self.data[idx]
