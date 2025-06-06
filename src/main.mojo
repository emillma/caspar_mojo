from caspar import funcs
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.val import Val, Call, CasparElement
from caspar.funcs import AnyFunc
from caspar.context import KernelData, kernel
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


fn foo() -> KernelData[SymConfigDefault]:
    var graph = Graph[SymConfigDefault]()
    var x = Vector[4, reader = Unique["x"]](graph)
    var y = Vector[4, reader = Unique["y"]](graph)
    var z = Vector[4, writer = Unique["z"]](graph)
    # z^.discard()
    # print("slice_size", len(z[:]))
    # alias foo = __type_of((0:2))
    return KernelData[SymConfigDefault](graph^)


fn slice_size(size: Int, indices: Tuple[Int, Int, Int], out ret: Int):
    var start, end, step = indices
    ret = (end - start + step - 1) // step
    debug_assert(ret >= 0, "Slice size has to be non-negative")


struct SliceInfo[target_size: Int, slice: Slice]:
    alias indices = slice.indices(target_size)
    alias size = slice_size(target_size, Self.indices)


@value
struct MyVec[size: Int]:
    fn __getitem__[
        sl: Slice,
    ](self, out ret: MyVec[size = SliceInfo[size, sl].size]):
        ret = MyVec[size = SliceInfo[size, sl].size]()


fn main() raises:
    var a = MyVec[10]()
    var b = a.__getitem__[::2]()
    print(b.size)  # prints 5
    # var c = a[::2] # error: invalid call to '__getitem__': expected at most 1 positional argument, got 2

    kernel[foo]()
    # print(a.take[funcs.StoreFloat]().value)
    # print(sizeof[StaticString]())
    # var x = Vector[4, read=Unique]("x", graph)
    # var y = Vector[4, read=Unique]("y", graph)
    # var z: Vector[4, write=Unique] = x + y
    # print(z[1])
    # b = Vector[4, write=Unique]("x", graph)
    # print(v[0])
    # print(v[1])
