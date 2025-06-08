from caspar import funcs
from caspar.collections import CallSet
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.storage import SymbolStorage, Storable
from caspar.sysconfig import GraphConfig, SymConfig, Config
from caspar.val import Val, Call
from collections import BitSet
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq


trait Accessor(Copyable & Movable):
    alias name_: StaticString
    alias size_: Int


trait Reader(Accessor):
    ...


trait Writer(Accessor):
    ...


@value
struct ReadUnique[name: StaticString, size: Int](Reader):
    alias name_ = name
    alias size_ = size

    fn __init__[T: Storable](out self: ReadUnique[name, T.size_], mut target: T):
        @parameter
        for i in range(T.size_):
            target[i] = target.graph().add_call(funcs.ReadValue[1](name, i))[0]
        self = Self()


struct WriteUnique[name: StaticString, size: Int](Writer):
    alias name_ = name
    alias size_ = size

    fn __init__[T: Storable](out self: WriteUnique[name, T.size_], target: T):
        @parameter
        for i in range(T.size_):
            _ = target.graph().add_call(funcs.WriteValue[1](name, i), target[i])
