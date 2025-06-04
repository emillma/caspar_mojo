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

    var graph: Pointer[Graph[config], origin]
    var data: IndexList[ValIdx, Self.size]
    var valid: BitSet[Self.size]

    fn __init__(out self: Self, ref [origin]graph: Graph[config]):
        self.graph = Pointer[Graph[config], origin](to=graph)
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
]:
    alias reader = read
    alias writer = read
    var data: SymbolStorage[size, config, origin]

    fn __copyinit__(out self: Self, other: Vector[size, config, origin]):
        self.data = other.data

    fn __init__(out self: Self, name: String, ref [origin]graph: Graph[config]):
        self.data = Self.reader.read[size=size](name, graph)

    fn __getitem__(self, idx: Int) -> Val[AnyFunc, config, origin]:
        return self.data[idx]

    # fn __add__(self, other: Self, out ret: Self):
    #     debug_assert(
    #         _type_is_eq(self, other),
    #         "Cannot add vectors of different types",
    #     )
    #     ret = Self(reader=self.reader, writer=self.writer)
    #     for i in range(self.data.size):
    #         ret.data[i] = self.data[i] + other.data[i]
    #     return ret
