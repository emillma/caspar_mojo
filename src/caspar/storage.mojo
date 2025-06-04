from caspar import funcs
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.val import Val, Call, CasparElement
from caspar.funcs import AnyFunc
from collections import BitSet
from caspar.accessor import Accessor, UnDefined

# from caspar.storage import ValStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.val import Val, GraphRef
from caspar.sysconfig import SymConfigDefault, SymConfig
from caspar.collections import ValIdx, IndexList
from caspar.collections import CallSet
from sys.intrinsics import _type_is_eq


struct SymbolStorage[size: Int, config: SymConfig, origin: ImmutableOrigin](
    Movable, Copyable
):
    alias ElemT = Val[AnyFunc, config, origin]

    var data: IndexList[ValIdx, Self.size]
    var valid: BitSet[Self.size]
    var graph: Pointer[Graph[config], origin]

    fn __init__(out self: Self, ref [origin]graph: Graph[config]):
        self = Self(Pointer(to=graph))

    fn __init__(out self: Self, graph: Pointer[Graph[config], origin]):
        self.graph = graph
        self.data = IndexList[ValIdx, Self.size]()
        self.valid = BitSet[Self.size]()

    fn __getitem__(self, idx: Int) -> Val[AnyFunc, config, origin]:
        debug_assert(self.valid.test(idx), "Index not valid")
        return Val[AnyFunc](self.graph, self.data[idx])

    fn __setitem__(mut self, idx: Int, owned value: Val[AnyFunc, config, origin]):
        debug_assert(not self.valid.test(idx), "Index not valid")
        self.valid.set(idx)
        self.data[idx] = value.idx


trait Storable:
    alias reader: Accessor
    alias writer: Accessor


struct Vector[
    size: Int,
    config: SymConfig,
    origin: ImmutableOrigin,
    *,
    read: Accessor = UnDefined,
    write: Accessor = UnDefined,
](Movable, Copyable):
    alias reader = read
    alias writer = read
    alias Undef = Vector[size, config, origin, read=UnDefined, write=UnDefined]
    alias Like = Vector[size, config, origin, read=_, write=_]
    var data: SymbolStorage[size, config, origin]

    @implicit
    fn __init__(
        out self: Self,
        owned other: Self.Like,
    ):
        self.data = other.data^
        __disable_del other

    fn __init__(out self: Self, name: String, ref [origin]graph: Graph[config]):
        @parameter
        if _type_is_eq[Self.reader, UnDefined]():
            self.data = SymbolStorage[size](graph)
        else:
            self.data = Self.reader.read[size=size](name, graph)

    fn __init__(out self: Self, graph: Pointer[Graph[config], origin]):
        self.data = SymbolStorage[size, config, origin](graph)

    fn __getitem__(self, idx: Int) -> Val[AnyFunc, config, origin]:
        return self.data[idx]

    fn __add__(self, other: Self.Like, out ret: Self.Like):
        ret = Self.Like(self.data.graph)
        for i in range(size):
            ret.data[i] = self.data.graph[].add_call(
                funcs.Add(), self.data[i], other.data[i]
            )[0]
