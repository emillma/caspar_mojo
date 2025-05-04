from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call
from caspar.sysconfig import SymConfigDefault, SymConfig, RunTimeDefault
from sys import sizeof
from caspar.storage import Storage, Vec
from caspar.graph import Graph, ReadSequential, WriteSequential


@value
struct Foo:
    fn __del__(owned self):
        print("Foo destructor called")


fn foo() -> String:
    x = Call[SymConfigDefault](Symbol("x"))[0]
    y = Call[SymConfigDefault](Symbol("y"))[0]
    v1 = Vec[Expr[SymConfigDefault], 2](x, y)
    v2 = Vec[Expr[SymConfigDefault], 2](x, x)
    var v3 = v1 + v2
    return Graph(ReadSequential(v1), WriteSequential(v3)).name

    # return String(v3[1]) + String(v3[0])


fn main():
    alias bar = foo()
    # alias kernel = Kernel[foo()]
    print(bar)
