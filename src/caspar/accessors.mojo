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

    @staticmethod
    fn read[
        size: Int, sym: SymConfig, origin: ImmutableOrigin
    ](
        name: StaticString,
        ref [origin]graph: Graph[sym],
        out ret: List[Val[sym, origin]],
    ):
        ...


@value
struct ReadUnique(Accessor):
    alias is_read = True

    @staticmethod
    fn read[
        size: Int, sym: SymConfig, origin: ImmutableOrigin
    ](
        name: StaticString,
        ref [origin]graph: Graph[sym],
        out ret: List[Val[sym, origin]],
    ):
        ret = List[Val[sym, origin]](capacity=size)

        @parameter
        for i in range(size):
            ret.append(graph.add_call(funcs.ReadValue[1](name, i))[0])


struct WriteUnique[name: StaticString, size: Int](Accessor):
    alias is_read = False

    @staticmethod
    fn read[
        size: Int, sym: SymConfig, origin: ImmutableOrigin
    ](
        name: StaticString,
        ref [origin]graph: Graph[sym],
        out ret: List[Val[sym, origin]],
    ):
        constrained[False, "Not a read accessor"]()
