from caspar import funcs
from caspar.graph import Graph
from caspar.val import Val, Call

# from caspar.storage import ValStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.val import Val, GraphRef
from caspar.sysconfig import SymConfigDefault, FuncCollectionDefault

from caspar.collections import CallSet


fn main():
    var graph = Graph[SymConfigDefault]()
    # Dict[String, Int]().setdefault("a", 1)
    var read_x = graph.add_call(funcs.Symbol("x"))
    var read_y = graph.add_call(funcs.Symbol("x"))
    var z = graph.add_call(funcs.Add(), read_x[0], read_y[0])[0]
    var call = z.call()[].copy()
    # print(graph.owns(z))
    # print(graph2.owns(z))
    print(z)


#
