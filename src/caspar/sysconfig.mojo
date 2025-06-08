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
from caspar import accessors
from compile.reflection import get_type_name

alias TraitType = AnyTrivialRegType


struct Collection[Trait: TraitType, *Ts: Trait]:
    alias count = len(VariadicList(Ts))


fn index_of[Trait: TraitType, *Ts: Trait, target: Trait]() -> Int:
    fn inner() -> Int:
        @parameter
        for i in range(len(VariadicList(Ts))):

            @parameter
            if _type_is_eq[Ts[i], target]():
                return i
        return -1

    alias idx = inner()
    alias name = String(__mlir_attr[`#kgen.get_type_name<`, target, `> : !kgen.string`])
    constrained[idx != -1, name + " not found in collection of types."]()
    return -1


trait SymConfig:
    alias func_types: __mlir_type[`!kgen.variadic<`, Callable, `>`]
    alias func_idx: fn[T: Callable] () -> Int
    alias access_types: __mlir_type[`!kgen.variadic<`, accessors.Accessor, `>`]
    alias access_idx: fn[T: accessors.Accessor] () -> Int

    # @staticmethod
    # fn supports[T: Callable]() -> Bool:
    #     ...


struct DefaultSymConfig(SymConfig):
    alias func_types = Collection[
        Callable,
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
    alias func_idx = index_of[Callable, Self.func_types, target=_]

    alias access_types = Collection[
        accessors.Accessor,
        accessors.WriteUnique,
        accessors.ReadUnique,
    ].Ts
    alias access_idx = index_of[accessors.Accessor, Self.access_types, target=_]


# @staticmethod
# fn supports[T: accessors.Accessor]() -> Bool:
#     return FuncVariant[*Self.func_types].supports[T]()
