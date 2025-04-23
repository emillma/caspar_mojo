from .expr import Call, Expr
from .functions import Symbol, Add


fn symbol(name: String) -> Expr:
    return Call(Symbol(name))[0]
