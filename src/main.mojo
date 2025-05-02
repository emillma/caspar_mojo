from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call
from caspar.sysconfig import SymConfigDefault, SymConfig, RunTimeDefault
from sys import sizeof
from caspar.storage import Storage, Vec


@value
struct Foo:
    fn __del__(owned self):
        print("Foo destructor called")


fn main():
    # var y = x
    # print(x + x)
    var x = Call[SymConfigDefault](Symbol("x"))[0]
    var y = Call[SymConfigDefault](Symbol("y"))[0]
    var v1 = Vec[Expr[SymConfigDefault], 2](x, y)
    var v2 = Vec[Expr[SymConfigDefault], 2](x, x)
    var v3 = v1 + v2
    print(v3[1])
    # print(v3[0])

    # var tot = Call[SymConfigDefault](Add(), List(x, y))[0]
    # var a = ExprOrData[SymConfig[False]()](3.2)
    # print(RunTimeDefault.add(x, y) + y)
    # print(tot)
    # print(String((x + y)))
