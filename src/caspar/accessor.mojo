from caspar import funcs
from caspar.collections import CallSet
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.storage import SymbolStorage, Storable
from caspar.sysconfig import SymConfigDefault, SymConfig
from caspar.val import Val, Call, CasparElement
from collections import BitSet
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq


trait Accessor(Copyable & Movable):
    @staticmethod
    fn read_into[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](mut ret: SymbolStorage[size, config, origin]):
        ...

    @staticmethod
    fn write[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](storage: SymbolStorage[size, config, origin],):
        ...


struct Unique[name: StaticString](Accessor):
    @staticmethod
    fn read_into[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](mut ret: SymbolStorage[size, config, origin]):
        for i in range(size):
            ret[i] = ret.graph[].add_call(funcs.ReadValue[1](name, i))[0]

    @staticmethod
    fn write[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](storage: SymbolStorage[size, config, origin],):
        for i in range(size):
            _ = storage.graph[].add_call(funcs.WriteValue[1](name, i), storage[i])


struct Arg[type: Storable, accessor: Accessor]:
    ...
    # @staticmethod
    # fn read[
    #     config: SymConfig, origin: ImmutableOrigin
    # ](ref [origin]graph: Graph[config], out ret: SymbolStorage[type.size, type.config, origin]):
    #     return accessor.read[size, config, origin](graph, out ret)

    # @staticmethod
    # fn write[
    #     size: Int, config: SymConfig, origin: ImmutableOrigin
    # ](storage: SymbolStorage[size, config, origin]):
    #     return accessor.write[size, config, origin](storage)
