from caspar import funcs
from caspar.collections import CallSet, ValIdx
from caspar.funcs import AnyFunc
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.storage import SymbolStorage, Storable
from caspar.sysconfig import SymConfig
from caspar.val import Val, Call
from collections import BitSet
from memory import UnsafePointer
from sys import sizeof, alignof
from sys.intrinsics import _type_is_eq


trait Accessor(Copyable & Movable):
    alias is_read: Bool

    fn get_data(self) -> AccessorData:
        ...

    # @staticmethod
    # fn read[
    #     size: Int, sym: SymConfig, origin: ImmutableOrigin
    # ](
    #     name: StaticString,
    #     ref [origin]graph: Graph[sym],
    #     out ret: List[Val[sym, origin]],
    # ):
    #     ...


@value
struct AccessorData:
    var name: StaticString
    var size: Int
    var type_idx: Int


struct ReadUnique(Accessor):
    alias is_read = True
    var data: AccessorData

    fn __init__[S: Storable](out self, data: S, name: StaticString = ""):
        self.data = AccessorData(name, S.size_, S.sym_.access_idx[Self]())
        # Initialize the read accessor

    fn get_data(self) -> AccessorData:
        return self.data

    # fn __init__(out self: ):
    # Initialize the read accessor with the name and size
    # @staticmethod
    # fn read[
    #     sym: SymConfig, origin: ImmutableOrigin
    # ](
    #     name: StaticString,
    #     ref [origin]graph: Graph[sym],
    #     out ret: List[Val[sym, origin]],
    # ):
    #     ret = List[Val[sym, origin]](capacity=size)

    #     @parameter
    #     for i in range(size):
    #         ret.append(graph.add_call(funcs.ReadValue[1](name, i))[0])


struct WriteUnique(Accessor):
    alias is_read = False
    var data: AccessorData

    fn __init__[S: Storable](out self, data: S, name: StaticString = ""):
        self.data = AccessorData(name, S.size_, S.sym_.access_idx[Self]())
        # Initialize the read accessor

    fn get_data(self) -> AccessorData:
        return self.data

    # @staticmethod
    # fn read[
    #     size: Int, sym: SymConfig, origin: ImmutableOrigin
    # ](
    #     name: StaticString,
    #     ref [origin]graph: Graph[sym],
    #     out ret: List[Val[sym, origin]],
    # ):
    #     constrained[False, "Not a read accessor"]()
    #     ret = []
