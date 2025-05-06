# from caspar.functions import Symbol, Add
# from caspar.expr import Expr, Call

# from sys import sizeof
# from caspar.storage import Storage, Vec
# from caspar.graph import Graph, ReadSequential, WriteSequential
# from random import seed
# from hashlib.hash import _HASH_SECRET
from caspar.sysconfig import SymConfigDefault, SymConfig, RunTimeDefault
from memory import UnsafePointer
from caspar.expr import GraphRef
from caspar.functions import Symbol, Add


fn foo() -> GraphRef[SymConfigDefault]:
    return GraphRef[SymConfigDefault](initialize=True)


fn main():
    var graph = GraphRef[SymConfigDefault](initialize=True)
    # var x = graph
    # var y = graph
    var x = graph.add_call(Symbol("x")).outs(0)
    var y = graph.add_call(Symbol("y")).outs(1)
    var z = graph.add_call(Add(), x, y).outs(0)
    print(x + y)
    # var call = Call(graph, 0)
    # add(x, y)
