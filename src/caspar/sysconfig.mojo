import .funcs
from .expr import Expr, Call
from stdlib.builtin.range import _SequentialRange
from sys.intrinsics import _type_is_eq
from os import abort


struct FuncCollection[*Ts: funcs.Callable]:
    alias vlist = VariadicList(Ts)
    alias size = len(Self.vlist)

    @staticmethod
    fn range() -> _SequentialRange:
        return range(0, len(Self.vlist))

    @staticmethod
    fn func_range() -> _SequentialRange:
        return range(0, len(Self.vlist))

    @staticmethod
    fn func_to_idx[T: funcs.Callable]() -> Int:
        constrained[Self.supports[T](), "Type not supported"]()

        @parameter
        for i in Self.func_range():

            @parameter
            if _type_is_eq[T, Self.Ts[i]]():
                return i

        return -1

    @staticmethod
    fn supports[T: funcs.Callable]() -> Bool:
        @parameter
        for i in Self.func_range():
            if _type_is_eq[T, Self.Ts[i]]():
                return True
        print("\n\n", T.fname, "\n\n")
        return False

    fn __init__(out self):
        ...

    fn __eq__(self, other: FuncCollection) -> Bool:
        @parameter
        if self.size != other.size:
            return False

        @parameter
        for i in self.range():

            @parameter
            if not _type_is_eq[Self.Ts[i], other.Ts[i]]():
                return False
        return True


@value
struct SymConfig[funcs: FuncCollection]:
    alias n_funcs = Self.funcs.size

    fn __init__(out self):
        ...

    fn __eq__(self, other: SymConfig[_]) -> Bool:
        return self.funcs == other.funcs


alias FuncCollectionDefault = FuncCollection[
    funcs.ReadValue[1],
    funcs.WriteValue[1],
    funcs.Add,
    funcs.Mul,
    funcs.StoreFloat,
    funcs.StoreOne,
    funcs.StoreZero,
]()
alias SymConfigDefault = SymConfig[FuncCollectionDefault]()


struct RunConfig:
    alias DType = SIMD[DType.float32, 1]
