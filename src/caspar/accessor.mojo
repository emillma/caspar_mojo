from caspar import funcs
from caspar.collections import CallSet
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.storage import SymbolStorage
from caspar.sysconfig import SymConfigDefault, SymConfig
from caspar.val import Val, Call, CasparElement
from collections import BitSet
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq


trait Accessor(Copyable & Movable):
    @staticmethod
    fn read[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](ref [origin]graph: Graph[config], out ret: SymbolStorage[size, config, origin],):
        ...

    @staticmethod
    fn write[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](storage: SymbolStorage[size, config, origin],):
        ...


struct Unique[name: StaticString](Accessor):
    @staticmethod
    fn read[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](ref [origin]graph: Graph[config], out ret: SymbolStorage[size, config, origin],):
        ret = SymbolStorage[size, config, origin](graph)
        for i in range(size):
            ret[i] = graph.add_call(funcs.ReadValue[1](name, i))[0]

    @staticmethod
    fn write[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](storage: SymbolStorage[size, config, origin],):
        for i in range(size):
            _ = storage.graph[].add_call(funcs.WriteValue[1](name, i), storage[i])


struct UnDefined(Accessor):
    @staticmethod
    fn read[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](ref [origin]graph: Graph[config], out ret: SymbolStorage[size, config, origin]):
        constrained[False, "Undefined accessor cannot write symbols"]()
        ret = SymbolStorage[size, config, origin](graph)

    @staticmethod
    fn write[
        size: Int, config: SymConfig, origin: ImmutableOrigin
    ](storage: SymbolStorage[size, config, origin]):
        constrained[False, "Undefined accessor cannot write symbols"]()
