import .funcs
from caspar.funcs import Callable, Symbol, Add
from .val import Val, Call
from stdlib.builtin.range import _SequentialRange
from sys.intrinsics import _type_is_eq
from os import abort
from utils import Variant
from sys.info import sizeof
from caspar.collections import CallableVariant, AccessorVariant
from caspar.graph import Graph
from caspar import accessors
from compile.reflection import get_type_name


alias FuncVariant = CallableVariant[
    funcs.Symbol,
    funcs.ReadValue[1],
    funcs.WriteValue[1],
    funcs.ReadValue[2],
    funcs.WriteValue[2],
    funcs.ReadValue[4],
    funcs.WriteValue[4],
    funcs.Add,
    funcs.Mul,
    funcs.StoreFloat,
    funcs.StoreOne,
    funcs.StoreZero,
]

alias AccessVariant = AccessorVariant[
    accessors.WriteUnique,
    accessors.ReadUnique,
]
# struct DefaultSymConfig(SymConfig):
#     alias FuncVariant = variants.FuncVariant[
#         funcs.Symbol,
#         funcs.ReadValue[1],
#         funcs.WriteValue[1],
#         funcs.ReadValue[2],
#         funcs.WriteValue[2],
#         funcs.Add,
#         funcs.Mul,
#         funcs.StoreFloat,
#         funcs.StoreOne,
#         funcs.StoreZero,
#     ]


# @staticmethod
# fn supports[T: accessors.Accessor]() -> Bool:
#     return FuncVariant[*Self.func_types].supports[T]()
