from caspar import funcs
from caspar.graph import GraphRef, SymFunc
from caspar.expr import Expr, Call, Value

from caspar.storage import ExprStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.expr import Expr, GraphRef
from caspar.sysconfig import SymConfigDefault


fn test() -> SymFunc[SymConfigDefault]:
    var graph = GraphRef[SymConfigDefault](initialize=True)
    var read_x = graph.add_call(funcs.ReadValue[1]("x"))
    var read_y = graph.add_call(funcs.ReadValue[1]("y"))
    var z = graph.add_call(funcs.Add(), read_x[0], read_y[0])[0]
    var store_z = graph.add_call(funcs.WriteValue[1](), z)
    # return a
    return graph.as_function(read_x, read_y, store_z)


fn main():
    print("hello world")
    test()
    # alias graph = symfunc.graph[]

    # print(graph.refcount)
    # print(sizeof[__type_of(graph)]())
    # print(symfunc.graph[].refcount)

    # @parameter
    # for i in range(len(symfunc.graph[].exprs)):
    #     print(symfunc.graph[].exprs[i].call_idx.type.__int__())

    #     # print(symfunc.graph[].exprs[i].call().args(2).idx)

    # # var x = symfunc.args[0]
    # # print(UnsafePointer(to=graph))
    # print(symfunc.graph.ptr)

    # print(symfunc.graph[].exprs[0])
    # var a = FuncTypeIdx(2)
    # print()
    # var foo = Storage[Expr[AnyFunc, SymConfigDefault], 3](uninitialized=True)
    # foo.init_unsafe(0, 3.3)

    # graph.set_args
    # var data = ExprStorage[3, SymConfigDefault](graph, x, y, z)

    # var w: Float64 = rebind[Float64](Float64(123))
    # print(last)
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
