# from caspar.compile import Kernel, Arg

# from caspar import accessors
from caspar.graph import Graph

from caspar.storage import Vector
from caspar import funcs
from sys.intrinsics import _type_is_eq


fn foo():
    var graph = Graph()
    var x = Vector[4]("x", graph)
    var y = Vector[4]("y", graph)

    print(x + y)
    # var bar = graph.make_kernel(
    #     accessors.ReadUnique(x),
    #     accessors.ReadUnique(y),
    #     # accessors.WriteUnique(z),
    # )


fn main():
    foo()
