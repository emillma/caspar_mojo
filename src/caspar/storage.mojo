from caspar import funcs
from caspar.calliter import CallChildIter
from caspar.collections import CallSet, CallIdx
from caspar.collections import ValIdx, IndexList
from caspar.funcs import AnyFunc
from caspar.graph import Graph, GraphT
from caspar.graph_core import GraphCore
from caspar.config import FuncVariant
from caspar.val import Val, Call
from collections import BitSet, Set
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq
from caspar.accessors import Accessor
from compile.reflection import get_type_name


struct SymbolStorage[size: Int, origin: ImmutableOrigin](Movable, Copyable, Sized):
    alias ElemT = Val[origin]

    var indices: IndexList[ValIdx, Self.size]
    var assigned: BitSet[Self.size]
    var graph: Pointer[Graph, origin]

    fn __init__(out self: Self, ref [origin]graph: Graph):
        self.graph = Pointer(to=graph)
        self.indices = IndexList[ValIdx, Self.size]()
        self.assigned = BitSet[Self.size]()

    fn __getitem__(self, idx: Int) -> Val[origin]:
        debug_assert(self.assigned.test(idx), "Index not valid")
        return Val(self.graph, self.indices[idx])

    fn __setitem__(mut self, idx: Int, owned value: Val[origin]):
        if not value.graph[].same_as(self.graph[]):
            debug_assert(False, "Cannot rebind to a different graph yet")
        debug_assert(not self.assigned.test(idx), "Index not valid")
        self.assigned.set(idx)
        self.indices[idx] = value.idx

    fn __len__(self) -> Int:
        return len(self.indices)


# trait Storable(Movable, Copyable, Sized):
#     alias size_: Int
#     alias GT: GraphT
#     alias sym_: SymConfig
#     alias origin_: ImmutableOrigin

#     fn graph(self) -> ref [Self.origin_] Graph[Self.sym_]:
#         ...

#     fn __getitem__(self, idx: Int) -> Val[Self.sym_, Self.origin_]:
#         ...

#     fn __setitem__(mut self, idx: Int, owned value: Val[Self.sym_, Self.origin_]):
#         ...


@fieldwise_init
struct Vector[
    size: Int,
    origin: ImmutableOrigin,
](Writable):
    alias size_ = size
    alias origin_ = origin
    var data: SymbolStorage[size, origin]

    fn __init__[
        origin: ImmutableOrigin
    ](out self: Vector[size, origin], name: StaticString, ref [origin]graph: Graph,):
        self.data = SymbolStorage[size, origin](graph)

        @parameter
        for i in range(size):
            self.data[i] = graph.add_call(funcs.Symbol(name, i))[0]

    fn __getitem__(self, idx: Int) -> Val[origin]:
        return self.data[idx]

    fn __setitem__(mut self, idx: Int, owned value: Val[origin]):
        self.data[idx] = value

    fn __add__(self, other: Self, out ret: Self):
        data = SymbolStorage[size, origin](graph=self.graph())
        for i in range(size):
            data[i] = self.graph().add_call(funcs.Add(), self[i], other[i])[0]
        ret = Self(data)

    fn __len__(self) -> Int:
        return len(self.data)

    fn graph(self) -> ref [origin] Graph:
        return self.data.graph[]

    fn to_storage(self) -> SymbolStorage[size, sym, origin]:
        return self.data

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("[")

        @parameter
        for i in range(size):
            writer.write(self[i], ", " if i < size - 1 else "")
        writer.write("]")

    # alias Generics: Storable
    # alias T: Storable
    # fn to_storage[
    #     new_origin: ImmutableOrigin
    # ](self, ref [new_origin]graph: Graph) -> SymbolStorage[
    #     Self.size_, Config[graph.sym, new_origin]
    # ]:

    #     ...

    # fn to_storage[
    #     new_origin: ImmutableOrigin
    # ](self, ref [new_origin]graph: Graph) -> SymbolStorage[
    #     Self.size_, graph.config, new_origin
    # ]:
    #     if self.data.graph[] is not graph:
    #         debug_assert(False, "Cannot rebind to a different graph yet")

    #     return rebind[SymbolStorage[Self.size_, graph.config, new_origin]](self.data)

    # fn to_storage(self) -> SymbolStorage[size, config, origin]:
    #     return self.data
    # debug_assert(len(self.data.assigned) == self.size, "Not all indices assigned")

    # fn discard(owned self):
    #     __disable_del self

    # ref graph = self.data.graph
    # var callmap = Dict[CallIdx, CallIdx]()
    # var valmat = Dict[ValIdx, ValIdx]()
    # var added = Set[CallIdx]()
    # for idx in self.data.indices:
    #     if idx not in added:
    #         added.add(idx)
    # var stack = [graph[]._core[idx].call for idx in self.data.indices]

    # for call in CallChildIter(calls^):
    #     print(call)
