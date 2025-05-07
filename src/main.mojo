from caspar.functions import Symbol, Add
from caspar.expr import GraphRef
from sys import sizeof, alignof

# from caspar.expr import Expr, GraphRef
from caspar.sysconfig import SymConfigDefault


fn main():
    var graph = GraphRef[SymConfigDefault](initialize=True)

    var x = graph.add_call(Symbol("x"))
    var z = graph.add_call(Symbol("z"))
    var y = graph.add_call(Add())
    print(sizeof[Byte]())
    # print(x.idx)
    # print(z.idx)
    # print(y.idx)
    # print(sizeof[GraphRef[SymConfigDefault]]())


#     var y = graph.add_call(Symbol("y")).outs(1)
#     var z = graph.add_call(Add(), x, y).outs(0)
#     print(z)
