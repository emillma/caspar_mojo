from caspar.functions import Symbol, Add, AnyFunc
from caspar.expr import GraphRef, Expr, Call
from sys import sizeof, alignof

# from caspar.expr import Expr, GraphRef
from caspar.sysconfig import SymConfigDefault


fn main():
    var graph = GraphRef[SymConfigDefault](initialize=True)

    var x = graph.add_call(Symbol("x"))
    var y = graph.add_call(Symbol("y"))
    var z = graph.add_call(Add(), x[0], y[0])[0]

    print(z)
    # var a = z.call()[].args[1]
    # var b = Expr[SymConfigDefault, AnyFunc](z).call()
    # print(sizeof[Byte]())
    # print(z)
    # print(z.idx)
    # print(y.idx)
    # print(sizeof[GraphRef[SymConfigDefault]]())


#     var y = graph.add_call(Symbol("y")).outs(1)
#     var z = graph.add_call(Add(), x, y).outs(0)
#     print(z)
