from caspar import funcs
from caspar.calliter import CallChildIter
from caspar.collections import CallSet, CallIdx
from caspar.collections import ValIdx, IndexList
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.sysconfig import SymConfigDefault, SymConfig, FuncCollection
from caspar.val import Val, Call, CasparElement
from collections import BitSet, Set
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq


fn slice_size(size: Int, indices: Tuple[Int, Int, Int], out ret: Int):
    var start, end, step = indices
    ret = (end - start + step - 1) // step
    debug_assert(ret >= 0, "Slice size has to be non-negative")


struct SliceInfo[target_size: Int, slice: Slice]:
    alias indices = slice.indices(target_size)
    alias size: Int = slice_size(target_size, Self.indices)
    alias range = range(Self.indices[0], Self.indices[1], Self.indices[2])


struct SymbolStorage[size: Int, config: SymConfig, origin: ImmutableOrigin](
    Movable, Copyable, Sized
):
    alias ElemT = Val[config, origin]

    var indices: IndexList[ValIdx, Self.size]
    var assigned: BitSet[Self.size]
    var graph: Pointer[Graph[config], origin]

    fn __init__(out self: Self, ref [origin]graph: Graph[config]):
        self = Self(Pointer(to=graph))

    fn __init__(out self: Self, graph: Pointer[Graph[config], origin]):
        self.graph = graph
        self.indices = IndexList[ValIdx, Self.size]()
        self.assigned = BitSet[Self.size]()

    fn __getitem__(self, idx: Int) -> Val[config, origin]:
        debug_assert(self.assigned.test(idx), "Index not valid")
        return Val(self.graph, self.indices[idx])

    fn __setitem__(mut self, idx: Int, owned value: Val[config, origin]):
        debug_assert(not self.assigned.test(idx), "Index not valid")
        self.assigned.set(idx)
        self.indices[idx] = value.idx

    fn __len__(self) -> Int:
        return len(self.indices)


trait Storable(Movable, Copyable, Sized):
    alias size_: Int

    fn to_storage[
        new_origin: ImmutableOrigin
    ](self, ref [new_origin]graph: Graph) -> SymbolStorage[
        Self.size_, graph.config, new_origin
    ]:
        ...


struct Vector[
    size: Int,
    config: SymConfig,
    origin: ImmutableOrigin,
](Storable):
    alias size_ = size
    alias config_ = config
    alias origin_ = origin
    var data: SymbolStorage[size, config, origin]

    fn __init__(out self, *, ref [origin]bind_to: Graph[config]):
        self.data = SymbolStorage[size](bind_to)

    fn __getitem__(self, idx: Int) -> Val[config, origin]:
        return self.data[idx]

    fn __setitem__(mut self, idx: Int, owned value: Val[config, origin]):
        self.data[idx] = value

    fn __add__(self, other: Self, out ret: Self):
        ret = Self(bind_to=self.data.graph[])
        for i in range(size):
            ret[i] = self.data.graph[].add_call(funcs.Add(), self[i], other[i])[0]

    fn __len__(self) -> Int:
        return len(self.data)

    fn to_storage[
        new_origin: ImmutableOrigin
    ](self, ref [new_origin]graph: Graph) -> SymbolStorage[
        Self.size_, graph.config, new_origin
    ]:
        if self.data.graph[] is not graph:
            debug_assert(False, "Cannot rebind to a different graph")

        return rebind[SymbolStorage[Self.size_, graph.config, new_origin]](self.data)

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
