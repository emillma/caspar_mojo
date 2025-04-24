from .callable import Callable, CallableVariant
from .functions import Symbol, Add
from .expr import Expr, Call
from .callable import Lookup, CallableVariant


struct SysConfig[*FuncTs: Callable]:
    alias FuncList = VariadicList[Callable](FuncTs)

    fn __init__(out self):
        ...


alias SysConfigDefault = SysConfig[Symbol, Add]()
