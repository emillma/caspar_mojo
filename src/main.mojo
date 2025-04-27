from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call
from caspar.sysconfig import SymConfigDefault, SymConfig
from sys import sizeof


fn main():
    # create_closure(MyStruct(8))
    # var a = 2
    # alias b = a^

    var x = Call[SymConfigDefault](Symbol("x"))[0]
    var y = Call[SymConfigDefault](Symbol("y"))[0]
    var tot = Call[SymConfigDefault](Add(), List(x, y))[0]

    # var a = ExprOrData[SymConfig[False]()](3.2)
    print(y)
    print(tot)
    # print(String((x + y)))
