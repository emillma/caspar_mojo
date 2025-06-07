from caspar import funcs
from caspar.accessor import Accessor, UnDefined
from caspar.calliter import CallChildIter
from caspar.collections import CallSet, CallIdx
from caspar.collections import ValIdx, IndexList
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.sysconfig import SymConfigDefault, SymConfig
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


trait Storable(Movable, Copyable):
    alias size_: Int
    alias reader_: Accessor
    alias writer_: Accessor

    fn copy_to(self, graph: Graph):
        ...


struct Vector[
    size: Int,
    config: SymConfig,
    origin: ImmutableOrigin,
    *,
    reader: Accessor = UnDefined,
    writer: Accessor = UnDefined,
](Storable, Sized):
    alias size_ = size
    alias reader_ = reader
    alias writer_ = writer
    alias Undef = Vector[size, config, origin, reader=UnDefined, writer=UnDefined]
    alias Like = Vector[size, config, origin, reader=_, writer=_]
    var data: SymbolStorage[size, config, origin]

    @implicit
    fn __init__(
        out self: Self,
        owned other: Self.Like,
    ):
        self.data = other.data^
        __disable_del other

    fn __init__(out self: Self, ref [origin]graph: Graph[config]):
        @parameter
        if _type_is_eq[Self.reader, UnDefined]():
            self.data = SymbolStorage[size](graph)
        else:
            self.data = Self.reader.read[size=size](graph)

    fn __init__(out self: Self, graph: Pointer[Graph[config], origin]):
        self.data = SymbolStorage[size, config, origin](graph)

    fn __getitem__(self, idx: Int) -> Val[config, origin]:
        return self.data[idx]

    fn __setitem__(mut self, idx: Int, owned value: Val[config, origin]):
        self.data[idx] = value

    fn __getitem__[
        sl: Slice,
    ](self, out ret: Vector[SliceInfo[size, sl].size, config, origin],):
        constrained[False, "Not implemented yet"]()
        ret = Vector[SliceInfo[size, sl].size, config, origin](self.data.graph)

    fn __setitem__[
        sl: Slice,
    ](mut self, owned val: Vector[_, config, origin]):
        constrained[SliceInfo[size, sl].size == val.size, "Slice size mismatch"]()

        @parameter
        for i in SliceInfo[size, sl].range:
            self[i] = val[i]

    # fn __setitem__(mut self, slice: Slice, owned value: Vector[_, config, origin]):
    #     print("setting")

    # return self.data[idx]

    fn __add__(self, other: Self.Like, out ret: Self.Undef):
        ret = Self.Undef(self.data.graph)
        for i in range(size):
            ret.data[i] = self.data.graph[].add_call(
                funcs.Add(), self.data[i], other.data[i]
            )[0]

    fn write(self):
        self.writer.write(self.data)

    fn __len__(self) -> Int:
        return len(self.data)

    fn copy_to(self, other_graph: Graph):
        ...

    fn __del__(owned self):
        @parameter
        if not _type_is_eq[Self.writer, UnDefined]():
            debug_assert(
                len(self.data.assigned) == self.size,
                "Not all indices assigned",
            )
            return self.writer.write(self.data)
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
