from caspar import funcs
from caspar.graph import Graph
from caspar.val import Val, Call

# from caspar.storage import ValStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.val import Val, GraphRef
from caspar.sysconfig import SymConfigDefault


fn main():
    var graph = Graph[SymConfigDefault]()
    var read_x = graph.add_call(funcs.ReadValue[1]("x"))
    var read_y = graph.add_call(funcs.ReadValue[1]("y"))
    var z = graph.add_call(funcs.Add(), read_x[0], read_y[0])[0]
    # print(graph.owns(z))
    # print(graph2.owns(z))
    print(z)
