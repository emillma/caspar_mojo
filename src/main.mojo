# from caspar.compile import Kernel, Arg

from caspar import accessors
from caspar.graph import Graph

from caspar.storage import Vector
from caspar import funcs
from sys.intrinsics import _type_is_eq

alias ArgKey = StaticString


fn foo():
    var graph = Graph()
    var x = Vector[4]("x", graph)
    var _ = Vector[4]("__", graph)
    var y = Vector[4]("y", graph)

    var bar = graph.make_kernel(
        accessors.ReadUnique(x, "x"),
        accessors.ReadUnique(y, "y"),
        accessors.WriteUnique(x + y, "z"),
    )


fn main():
    foo()
    # accessors.ReadUnique[Vector[4]]
