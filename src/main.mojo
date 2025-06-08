from caspar import funcs
from caspar.compile import Kernel
from caspar import accessors
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore

from caspar.sysconfig import DefaultSymConfig, SymConfig
from caspar.storage import Vector

# from gpu import thread_idx, block_idx, global_idx, warp, barrier
# from gpu.host import DeviceContext, Attribute


fn foo(out graph: Graph[DefaultSymConfig]):
    graph = Graph[DefaultSymConfig]()
    var x = Vector[4]("x", graph)
    var foo = Kernel(graph)


fn main():
    print("Start")
    foo()
    # print(c)
    # print(String(_type_is_eq[Float32, Int]()))
    # var graph = Graph[DefaultGraphConfig]()
    # var x = graph.add_call(funcs.Symbol("a"))
    # var x = Vector[4](graph).read[Unique["x"]]()
    # var y = Vector[4](graph).read[Unique["y"]]()

    # print(a.take[funcs.StoreFloat]().value)
    # print(sizeof[StaticString]())
    # var x = Vector[4, read=Unique]("x", graph)
    # var y = Vector[4, read=Unique]("y", graph)
    # var z: Vector[4, write=Unique] = x + y
    # print(z[1])
    # b = Vector[4, write=Unique]("x", graph)
    # print(v[0])
    # print(v[1])
