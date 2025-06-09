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
from caspar import args


trait Accessor(Copyable & Movable):
    alias is_read: Bool
    alias arg_type_key: StaticString

    fn read_and_map(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        ...

    fn map_and_write(self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        ...


struct Unique[read: Bool, StorageT: Storable](Accessor):
    alias is_read = read
    alias arg_type_key = args.PtrArg.arg_type_key
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
        for i in range(StorageT.size_):
            graph.copy_val(self.target[i], val_map)


alias ReadUnique = Unique[True, _]
alias WriteUnique = Unique[False, _]
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
