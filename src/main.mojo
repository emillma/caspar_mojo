from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call

# alias FuncT = CallableVariantDefault


fn main():
    var x = Call[Add, Symbol](Symbol("x"))[0]
    var y = Call[Add, Symbol](Symbol("y"))[0]
    print(y.print())
    print(String((y)))
    print(String((x + y)))
