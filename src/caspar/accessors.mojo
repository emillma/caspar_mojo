from caspar import funcs
from caspar.collections import CallSet, ValIdx, IndexList
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.storage import SymbolStorage, Storable
from caspar.val import Val, Call
from collections import BitSet
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq
from caspar.config import AccessVariant


trait Accessor(Copyable & Movable):
    alias is_read: Bool

    fn read_into(self, graph: Graph, out ret: IndexList[ValIdx]):
        ...

    fn write_from[T: Storable](self, data: T):
        ...


@value
struct AccessorData:
    var name: StaticString
    var size: Int
    var type_idx: Int


struct ReadUnique(Accessor):
    alias is_read = True
    var name: StaticString
    var target: AccessorData

    fn __init__[S: Storable](out self, target: S, name: StaticString = ""):
        self.target = AccessorData(name, S.size_, AccessVariant.type_idx_of[Self]())
        self.name = name

    fn read_into(self, graph: Graph, out ret: IndexList[ValIdx]):
        ret = IndexList[ValIdx](capacity=self.target.size)
        for i in range(self.target.size):
            ret.append(graph.add_call(funcs.ReadValue[1](self.name, i))[].outs[0])

    fn write_from[T: Storable](self, data: T):
        debug_assert(False, "ReadUnique does not support writing from data")


struct WriteUnique(Accessor):
    alias is_read = False
    var target: AccessorData
    var name: StaticString

    fn __init__[S: Storable](out self, target: S, name: StaticString = ""):
        self.target = AccessorData(name, S.size_, AccessVariant.type_idx_of[Self]())
        self.name = name

    fn read_into(self, graph: Graph, out ret: IndexList[ValIdx]):
        debug_assert(False, "WriteUnique does not support reading into an IndexList")
        ret = IndexList[ValIdx]()

    fn write_from[T: Storable](self, data: T):
        constrained[not Self.is_read, "Not a write accessor"]()

    # @staticmethod
    # fn read[
    #     size: Int, sym: SymConfig, origin: ImmutableOrigin
    # ](
    #     name: StaticString,
    #     ref [origin]graph: Graph[sym],
    #     out ret: List[Val[sym, origin]],
    # ):
    #     constrained[False, "Not a read accessor"]()
    #     ret = []
