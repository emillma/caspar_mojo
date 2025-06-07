# from caspar.context import KernelData, kernel
# from caspar.storage import ValStorage
# from caspar.val import Val, GraphRef
from caspar import funcs

# from caspar.accessor import Accessor, Unique, Arg
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore

# from caspar.storage import Storable, Vector
from caspar.sysconfig import DefaultGraphConfig, SymConfig
from caspar.val import Val, Call
from gpu import thread_idx, block_idx, global_idx, warp, barrier
from gpu.host import DeviceContext, Attribute
from pathlib import Path
from utils import Variant


# fn foo() -> KernelData[SymConfigDefault]:
#     var graph = Graph[SymConfigDefault]()

#     var x = Vector[4](graph).read[Unique["x"]]()
#     var y = Vector[4](graph).read[Unique["y"]]()
#     (x + y).write[Unique["z"]]()

#     # var z = Vector[4](graph).write[Unique["z"]]()
#     # var y: Arg[Unique["y"]] =
#     # var x = Arg[Vector[4], Unique['x']].read(graph)
#     # var x = Vector[4, reader = Unique["x"]](graph)
#     # var y = Vector[4, reader = Unique["y"]](graph)
#     # var z = Vector[4, writer = Unique["z"]](graph)
#     # z.__setitem__[Slice(None, None, None)](x + y)
#     # z^.discard()
#     # print("slice_size", len(z[:]))
#     # alias foo = __type_of((0:2))
#     return KernelData[SymConfigDefault](graph^)


fn main() raises:
    var graph = Graph[DefaultGraphConfig]()
    var x = graph.add_call(funcs.Symbol("a"))
    # var x = Vector[4](graph).read[Unique["x"]]()
    # var y = Vector[4](graph).read[Unique["y"]]()
    # kernel[foo]()

    # print(a.take[funcs.StoreFloat]().value)
    # print(sizeof[StaticString]())
    # var x = Vector[4, read=Unique]("x", graph)
    # var y = Vector[4, read=Unique]("y", graph)
    # var z: Vector[4, write=Unique] = x + y
    # print(z[1])
    # b = Vector[4, write=Unique]("x", graph)
    # print(v[0])
    # print(v[1])
