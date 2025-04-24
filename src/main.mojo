from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call
from caspar.sysconfig import SysConfigDefault


trait Config:
    alias Ts: VariadicList[Int]


struct MyConfig[*vals: Int]:
    alias Ts = VariadicList(vals)


fn foo[conf: Config]():
    ...


fn main():
    foo[MyConfig[1, 2, 3]]()
    var x = Call[SysConfigDefault](Symbol("x"))[0]
    var y = Call[SysConfigDefault](Symbol("y"))[0]

    print(y)
    print(x + y)
    # print(String((x + y)))
