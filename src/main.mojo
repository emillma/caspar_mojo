from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call

# alias FuncT = CallableVariantDefault


fn main():
    var x = Call(Symbol("x"))[0]
    var y = Call(Symbol("y"))[0]

    print(String((y)))
    print(String((x + y)))
