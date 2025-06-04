from caspar import funcs
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.val import Val, Call, CasparElement
from caspar.funcs import AnyFunc
from caspar.context import KernelData, make_kernel, Args
from pathlib import Path
from gpu import thread_idx, block_idx, global_idx, warp, barrier

from gpu.host import DeviceContext, Attribute

# from caspar.storage import ValStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.val import Val, GraphRef
from caspar.sysconfig import SymConfigDefault, FuncCollectionDefault

from caspar.collections import CallSet
from sys.intrinsics import _type_is_eq

from caspar.storage import Storable, Vector
from caspar.accessor import Accessor, Unique


fn foo() -> KernelData[SymConfigDefault]:
    var graph = Graph[SymConfigDefault]()
    var read_x = graph.add_call(funcs.ReadValue[1]("x", 0))
    var read_y = graph.add_call(funcs.ReadValue[1]("y", 0))
    var get_z = graph.add_call(funcs.Add(), read_x[0], read_y[0])
    var write_z = graph.add_call(funcs.WriteValue[1]("z", 0), get_z[0])
    return KernelData[SymConfigDefault](
        order=[[read_x.idx, read_y.idx, get_z.idx, write_z.idx]],
        regmap={read_x[0].idx: 0, read_y[0].idx: 1, get_z[0].idx: 1},
        graph=graph^.take_core(),
    )


fn main() raises:
    var graph = Graph[SymConfigDefault]()

    v = Vector[4, read=Unique]("x", graph)
    b = Vector[4, write=Unique]("x", graph)
    print(v[0])
    print(v[1])
