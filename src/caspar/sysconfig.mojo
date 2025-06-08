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
from caspar.accessors import Accessor

alias TraitType = __type_of(AnyType)


struct Collection[Trait: TraitType, *Ts: Trait]:
    ...


fn index_of[Trait: TraitType, T: Trait, *Ts: Trait]() -> Int:
    @parameter
    for i in range(len(VariadicList(Ts))):
        if _type_is_eq[Ts[i], T]():
            return i
    debug_assert(False, "Type not found in collection")
    return -1


trait SymConfig:
    alias func_types: __mlir_type[`!kgen.variadic<`, Callable, `>`]
    alias func_idx: fn[T: Callable] () -> Int

    @staticmethod
    fn supports[T: Callable]() -> Bool:
        ...


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
    alias func_idx = index_of[Callable, _, *Self.func_types]

    @staticmethod
    fn supports[T: Callable]() -> Bool:
        return FuncVariant[*Self.func_types].supports[T]()
