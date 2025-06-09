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


trait Accessor(Copyable & Movable):
    alias is_read: Bool

    fn read_and_map(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        ...

    fn map_and_write(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        ...


struct AccessorData(Copyable & Movable):
    var name: StaticString
    var size: Int
    var type_idx: Int
    var indices: IndexList[ValIdx]

    fn __init__[T: Storable](out self, name: StaticString, type_idx: Int, target: T):
        self.name = name
        self.size = T.size_
        self.type_idx = type_idx
        self.indices = IndexList[ValIdx](capacity=T.size_)
        for i in range(T.size_):
            self.indices.append(target[i].idx)


struct ReadUnique[StorageT: Storable](Accessor):
    alias is_read = True
    var target: StorageT
    var name: StaticString

    fn __init__(out self, target: StorageT, name: StaticString = ""):
        self.target = target
        self.name = name

    fn read_and_map(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        for i in range(StorageT.size_):
            var call = graph.add_call(funcs.ReadValue[1](self.name, i))
            val_map[self.target[i].idx] = call[].outs[0]

    fn map_and_write(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        debug_assert(False, "ReadUnique does not support writing from data")


struct WriteUnique[StorageT: Storable](Accessor):
    alias is_read = False
    var target: StorageT
    var name: String

    fn __init__(out self, target: StorageT, name: StaticString = ""):
        self.target = target
        self.name = name

    fn read_and_map(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        debug_assert(False, "WriteUnique does not support reading into an IndexList")

    fn map_and_write(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        for i in range(StorageT.size_):
            graph.copy_val(self.target[i], val_map)

        # for i in range(self.data.size):
        #     graph.copy_val(
        #         self.data.indices[i], funcs.WriteValue[1](self.name, i).outs[0]
        #     )
        #     var call = graph.add_call(funcs.ReadValue[1](self.data.name, i))
        #     val_map[self.data.indices[i]] = call[].outs[0]

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
