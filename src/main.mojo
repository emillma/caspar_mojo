from caspar import funcs
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.val import Val, Call, CasparElement
from caspar.funcs import AnyFunc
from caspar.context import KernelData
from pathlib import Path
from gpu import thread_idx, block_idx, global_idx, warp, barrier

from gpu.host import DeviceContext, Attribute

# from caspar.storage import ValStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.val import Val, GraphRef
from caspar.sysconfig import SymConfigDefault, FuncCollectionDefault, SymConfig

from caspar.collections import CallSet
from sys.intrinsics import _type_is_eq
from compile.reflection import get_type_name
from caspar.storage import Storable, Vector
from caspar.accessor import Accessor, Unique
from utils import Variant
from caspar.calliter import CallChildIter


fn foo():
    var a = funcs.ReadValue[1]("hello", 0)
    var b = funcs.ReadValue[1]("hello", 0)
    print(hash(a) == hash(b))
    var graph = Graph[SymConfigDefault]()
    var x = Vector[4, reader = Unique["x"]](graph)
    var y = Vector[4, reader = Unique["x"]](graph)
    var z = Vector[4, writer = Unique["z"]](x + y)
    for child in CallChildIter(z[1].call()):
        print(child)
    # print(z[2].call())
    var kernel = KernelData[SymConfigDefault](z)


fn main() raises:
    foo()
    alias ftype = Variant[funcs.Add, funcs.Symbol]
    # print(a.take[funcs.StoreFloat]().value)
    # print(sizeof[StaticString]())
    # var x = Vector[4, read=Unique]("x", graph)
    # var y = Vector[4, read=Unique]("y", graph)
    # var z: Vector[4, write=Unique] = x + y
    # print(z[1])
    # b = Vector[4, write=Unique]("x", graph)
    # print(v[0])
    # print(v[1])
