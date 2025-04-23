from caspar.functions import CallableVariantDefault, Symbol, Add
from caspar.expr import Expr, Call

alias FuncT = CallableVariantDefault


fn main():
    var x = Call(Symbol("x"))[0]
    var y = Call(Symbol("y"))[0]

    print(String((x + y).args()[0]))
