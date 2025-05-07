from .callable import Callable, CallableVariant
from .functions import Symbol, Add
from .expr import Expr, Call
from stdlib.builtin.range import _SequentialRange
from sys.intrinsics import _type_is_eq


struct FuncCollection[*Ts: Callable]:
    alias vlist = VariadicList(Ts)
    alias size = len(Self.vlist)

    @staticmethod
    fn range() -> _SequentialRange:
        return range(0, len(Self.vlist))

    @staticmethod
    fn func_range() -> _SequentialRange:
        return range(0, len(Self.vlist))

    @staticmethod
    fn func_to_idx[T: Callable]() -> Int:
        @parameter
        for i in Self.func_range():

            @parameter
            if _type_is_eq[T, Self.Ts[i]]():
                return i
        return -1

    fn __init__(out self):
        ...


struct SymConfig[callables: FuncCollection]:
    fn __init__(out self):
        ...


struct RunTime[sym_config: SymConfig]:
    alias Expr = Expr[Self.sym_config]
    alias Call = Call[Self.sym_config]
    # from math import floor

    # alias floor = floor

    @staticmethod
    fn add(a: Self.Expr, b: Self.Expr) -> Self.Expr:
        # print(Self.floor(3.3))
        return Self.Call(Add(), List[Self.Expr](a, b))[0]

    @staticmethod
    fn add[
        dtype: DType, size: Int
    ](a: SIMD[dtype, size], b: SIMD[dtype, size]) -> SIMD[dtype, size]:
        return a + b

    fn __init__(out self):
        ...


alias FuncCollectionDefault = FuncCollection[Symbol, Add]()
alias SymConfigDefault = SymConfig[FuncCollectionDefault]()
alias RunTimeDefault = RunTime[SymConfigDefault]()


struct RunConfig:
    alias DType = SIMD[DType.float32, 1]
