from caspar.funcs import Symbol, Add, AnyFunc, Callable
from caspar.graph import GraphRef
from caspar.expr import Expr, Call, Value

# from caspar.storage import Storage
from sys import sizeof, alignof

# from caspar.expr import Expr, GraphRef
from caspar.sysconfig import SymConfigDefault


fn main():
    var graph = GraphRef[SymConfigDefault](initialize=True)
    # var a = FuncTypeIdx(2)
    print()
    # var foo = Storage[Expr[AnyFunc, SymConfigDefault], 3](uninitialized=True)
    # foo.init_unsafe(0, 3.3)
    var x = graph.add_call(Symbol("x"))
    var y = graph.add_call(Symbol("y"))
    var z = graph.add_call(Add(), x[0], y[0])[0]
    var w: Float64 = rebind[Float64](Float64(123))
    print(z)
    # print(Int(z.idx))
    # var a = z.call()[].args[1]
    # var b = Expr[SymConfigDefault, AnyFunc](z).call()
    # print(sizeof[Byte]())
    # print(z.idx)
    # print(y.idx)
    # print(sizeof[GraphRef[SymConfigDefault]]())


#     var y = graph.add_call(Symbol("y")).outs(1)
#     var z = graph.add_call(Add(), x, y).outs(0)
#     print(z)
