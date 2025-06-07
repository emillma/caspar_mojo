import .funcs
from caspar.funcs import Callable, Symbol, Add
from .val import Val, Call
from stdlib.builtin.range import _SequentialRange
from sys.intrinsics import _type_is_eq
from os import abort
from utils import Variant
from sys.info import sizeof
from caspar.collections import FuncVariant
from caspar.graph import Graph


struct FuncCollection[*Ts: funcs.Callable](Sized):
    alias bar = __type_of(Ts)
    alias vlist = VariadicList(Ts)
    var size: Int

    fn __init__(out self):
        self.size = len(Self.vlist)

        @parameter
        for i in Self.range():

            @parameter
            for j in range(i):
                ...
                # constrained[
                #     Ts[i].info.fname != Ts[j].info.fname,
                #     "Duplicate function names: "
                #     + Ts[i].info.fname
                #     + " and "
                #     + Ts[j].info.fname,
                # ]()

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
        return False

    fn __eq__(self, other: FuncCollection) -> Bool:
        @parameter
        if len(Self.vlist) != len(other.vlist):
            return False

        @parameter
        for i in self.range():

            @parameter
            if not _type_is_eq[Self.Ts[i], other.Ts[i]]():
                return False
        return True

    fn __len__(self) -> Int:
        return self.size


# struct SymConfig[funcs: FuncCollection]:
#     alias func_types = funcs.Ts

#     fn __init__(out self):
#         ...

#     fn __eq__(self, other: SymConfig[_]) -> Bool:
#         return self.funcs == other.funcs


alias FuncCollectionDefault = FuncCollection[
    funcs.Symbol,
    funcs.ReadValue[1],
    funcs.WriteValue[1],
    funcs.ReadValue[2],
    funcs.WriteValue[2],
    # funcs.ReadValue[4],
    # funcs.WriteValue[4],
    funcs.Add,
    funcs.Mul,
    funcs.StoreFloat,
    funcs.StoreOne,
    funcs.StoreZero,
]()


trait SymConfig:
    alias func_types: __mlir_type[`!kgen.variadic<`, Callable, `>`]

    @staticmethod
    fn supports[T: Callable]() -> Bool:
        ...

    # alias origin: ImmutableOrigin
    # alias funcs: Variadic[Callable]


struct DefaultGraphConfig(SymConfig):
    alias func_types = FuncCollection[
        funcs.Symbol,
        funcs.ReadValue[1],
        funcs.WriteValue[1],
        funcs.ReadValue[2],
        funcs.WriteValue[2],
        # funcs.ReadValue[4],
        # funcs.WriteValue[4],
        funcs.Add,
        funcs.Mul,
        funcs.StoreFloat,
        funcs.StoreOne,
        funcs.StoreZero,
    ].Ts

    @staticmethod
    fn supports[T: Callable]() -> Bool:
        return FuncVariant[*Self.func_types].supports[T]()


trait RunConfig:
    alias sym: SymConfig
    alias origin: ImmutableOrigin

    @staticmethod
    fn check(graph: Graph):
        ...


struct Config[sym_config: SymConfig, origin_: ImmutableOrigin](RunConfig):
    alias sym = sym_config
    alias origin = origin_

    @staticmethod
    fn check(graph: Graph):
        constrained[
            _type_is_eq[Self.sym, graph.sym](),
            "Graph type mismatch",
        ]()
        # constrained[
        #     __origin_of(graph) == Self.origin,
        #     "Graph origin must match the config origin",
        # ]()
