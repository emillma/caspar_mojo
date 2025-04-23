from .callable import Callable, CallableVariant
from .expr import Expr


@value
struct Symbol(Callable):
    alias n_args = 0
    alias n_outs = 1

    var _data: String

    fn repr(self, args: List[String]) -> String:
        return self._data


@value
struct Add(Callable):
    alias n_args = 2
    alias n_outs = 1

    fn repr(self, args: List[String]) -> String:
        return args[0] + " + " + args[1]


alias CallableVariantDefault = CallableVariant[Symbol, Add]
