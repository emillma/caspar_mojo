# from .accessor import Accessor
from .expr import Expr, CasparElement
from .sysconfig import SymConfig
from memory import UnsafePointer
from caspar.graph import GraphRef

from .sysconfig import SymConfig, SymConfigDefault
from .funcs import AnyFunc


trait Storable(Movable & Copyable):
    alias elemT: Movable & Copyable


@value
struct ExprStorage[size: Int, config: SymConfig](Storable):
    alias elemT = Expr[AnyFunc, config]
    var _array: __mlir_type[`!pop.array<`, size.value, `, `, Self.elemT, `>`]
    var graph: GraphRef[config]

    fn __init__[
        *Ts: CasparElement
    ](out self, graph: GraphRef[config], owned *args: *Ts,):
        self = Self(graph, args^)

    fn __init__[
        *Ts: CasparElement
    ](
        out self,
        graph: GraphRef[config],
        owned args: VariadicPack[True, _, CasparElement, *Ts],
    ):
        constrained[Self.size == len(VariadicList(Ts)), "Invalid number of arguments"]()
        self.graph = graph
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self._array))

        @parameter
        fn inner[idx: Int, T: CasparElement](arg: T):
            self.unsafe_ptr().offset(idx).init_pointee_move(arg.as_expr(self.graph))

        args.each_idx[inner]()
        __disable_del args

    fn __getitem__(self, idx: Int) -> ref [self] Self.elemT:
        return self.unsafe_ptr().offset(idx)[]

    fn __len__(self) -> Int:
        return self.size

    fn init_unsafe(mut self, idx: Int, owned value: Self.elemT):
        """Set the value at the given index without bound checking
        and without running destructor of existing value."""
        self.unsafe_ptr().offset(idx).init_pointee_move(value^)

    @always_inline
    fn unsafe_ptr(
        ref self,
    ) -> UnsafePointer[
        Self.elemT,
        mut = Origin(__origin_of(self)).mut,
        origin = __origin_of(self),
    ]:
        return (
            UnsafePointer(to=self._array)
            .bitcast[Self.elemT]()
            .origin_cast[origin = __origin_of(self)]()
        )


# trait Storable(Movable & Copyable):
#     alias elemT: CasparElement
#     alias size: Int

#     fn to_storage(self) -> Storage[Self.elemT, Self.size]:
#         ...

#     @staticmethod
#     fn from_storage(owned storage: Storage[elemT, size]) -> Self:
#         ...


# @value
# struct Vec[elemT_: CasparElement, size_: Int](Storable):
#     alias size = size_
#     alias elemT = elemT_

#     alias Storage = Storage[Self.elemT, Self.size]
#     var storage: Self.Storage

#     fn __init__(out self, owned *args: elemT_):
#         debug_assert(len(args) == Self.size, "Invalid number of arguments")
#         self.storage = Self.Storage(storage=args^)

#     @staticmethod
#     fn from_storage(owned storage: Self.Storage) -> Self:
#         return Self(storage=storage)

#     fn to_storage(self) -> Storage[Self.elemT, Self.size]:
#         return self.storage

# return self.storage

# return self.storage

# fn __add__(self, other: Self) -> Self:
#     var storage = Self.Storage(uninitialized=True)
#     for i in range(0, self.storage.size):
#         storage.init_unsafe(i, self.storage[i] + other.storage[i])
#     return Self(storage=storage^)

# fn __getitem__(ref self, idx: Int) -> ref [self.storage.data] Self.elemT:
#     return self.storage[idx]
