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
from caspar import kernel_args


fn arg_name[i: Int]() -> String:
    return "arg" + String(i)


trait Accessor(Copyable & Movable):
    alias IS_READ: Bool
    alias ArgT: kernel_args.Argument

    fn read_and_map[arg: Int](self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        ...

    fn map_and_write[arg: Int](self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        ...


struct Unique[StorageT: Storable, //, read: Bool](Accessor):
    alias IS_READ = read
    alias ArgT = kernel_args.PtrArg[StorageT.size_]
    var target: StorageT

    fn __init__(out self, target: StorageT):
        self.target = target

    fn read_and_map[arg: Int](self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        for i in range(StorageT.size_):
            var call = graph.add_call(funcs.ReadValue[1](arg, i))
            val_map[self.target[i].idx] = call[].outs[0]

    fn map_and_write[arg: Int](self, graph: Graph, mut val_map: Dict[ValIdx, ValIdx]):
        for i in range(StorageT.size_):
            new_val = graph.copy_val(self.target[i], val_map)
            _ = graph.add_call(funcs.WriteValue[1](arg, i), new_val)


alias ReadUnique = Unique[True]
alias WriteUnique = Unique[False]
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
