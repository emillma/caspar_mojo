from .callable import Callable, CallableVariant
from .functions import Symbol, Add
from .expr import Expr, Call
from stdlib.builtin.range import _SequentialRange


struct FuncCollection[*Ts: Callable]:
    alias vlist = VariadicList(Ts)

    @staticmethod
    fn range() -> _SequentialRange:
        return range(0, len(Self.vlist))

    fn __init__(out self):
        ...


struct SymConfig[callables: FuncCollection]:
    fn __init__(out self):
        ...


struct RunTime[callables: FuncCollection]:
    alias sym_config = SymConfig[callables]()
    alias Expr = Expr[Self.sym_config]
    alias Call = Call[Self.sym_config]


alias SymConfigDefault = SymConfig[FuncCollection[Symbol, Add]()]()


struct RunConfig:
    alias DType = SIMD[DType.float32, 1]
