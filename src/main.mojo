from caspar.context import Kernel

# from caspar.storage import ValStorage
# from caspar.val import Val, GraphRef
from caspar import funcs

from caspar import accessors as arg
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore

from caspar.sysconfig import DefaultSymConfig, SymConfig
from caspar.val import Val, Call
from gpu import thread_idx, block_idx, global_idx, warp, barrier
from gpu.host import DeviceContext, Attribute
from pathlib import Path
from utils import Variant
from caspar.storage import Vector
from sys.intrinsics import _type_is_eq


struct B:
    alias foo = A
    alias name = "123"


@value
struct A:
    alias bar = B


fn foo(out graph: Graph[DefaultSymConfig]):
    graph = Graph[DefaultSymConfig]()
    var x = Vector[4]("x", graph)
    var y = Vector[4]("y", graph)
    var z = x + y
    print(z)
    # var y = Vector[4](graph).read[arg.Unique["y"]]()
    # (x + y).write[arg.Unique["z"]]()
    # var z = x + y

    # var a = A()
    # print(a.bar.name)
    # arg.Unique["z"].write(x + y)

    # for i in range(4):
    #     z[i] = x[i]
    # graph2 = Graph[DefaultSymConfig]()
    # x2 = Vector[4, read = arg.Unique["x"]](graph2)
    # z[0] = x2[0]

    # x = Vector[4].read[Unique["x"]](kernel)
    # alias foo = Arg[Vector[4], Unique["x"]]
    # var x = Vector[4].(Unique["x"].read(graph))

    # print("hello", StaticString(Vector[4].tname))
    # var x = argtype.read(graph)
    # var x = Vector[4](graph).read[Unique["x"]]()
    # var y = Vector[4](graph).read[Unique["y"]]()
    # (x + y).write[Unique["z"]]()

    # var z = Vector[4](graph).write[Unique["z"]]()
    # var y: Arg[Unique["y"]] =
    # var x = Arg[Vector[4], Unique['x']].read(graph)
    # var x = Vector[4, reader = Unique["x"]](graph)
    # var y = Vector[4, reader = Unique["y"]](graph)
    # var z = Vector[4, writer = Unique["z"]](graph)
    # z.__setitem__[Slice(None, None, None)](x + y)
    # z^.discard()
    # print("slice_size", len(z[:]))
    # alias foo = __type_of((0:2))
    # return kernel^


fn main():
    # print(c)
    # print(String(_type_is_eq[Float32, Int]()))
    # var graph = Graph[DefaultGraphConfig]()
    # var x = graph.add_call(funcs.Symbol("a"))
    # var x = Vector[4](graph).read[Unique["x"]]()
    # var y = Vector[4](graph).read[Unique["y"]]()
    foo()

    # print(a.take[funcs.StoreFloat]().value)
    # print(sizeof[StaticString]())
    # var x = Vector[4, read=Unique]("x", graph)
    # var y = Vector[4, read=Unique]("y", graph)
    # var z: Vector[4, write=Unique] = x + y
    # print(z[1])
    # b = Vector[4, write=Unique]("x", graph)
    # print(v[0])
    # print(v[1])
