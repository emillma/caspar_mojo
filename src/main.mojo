# from caspar import funcs
# from caspar.graph import Graph
# from caspar.graph_core import GraphCore
# from caspar.val import Val, Call, CasparElement
# from caspar.funcs import AnyFunc
# from caspar.context import KernelData, kernel
# from pathlib import Path
# from gpu import thread_idx, block_idx, global_idx, warp, barrier

# from gpu.host import DeviceContext, Attribute

# # from caspar.storage import ValStorage
# from sys import sizeof, alignof
# from memory import UnsafePointer

# # from caspar.val import Val, GraphRef
# from caspar.sysconfig import SymConfigDefault, FuncCollectionDefault, SymConfig

# from caspar.collections import CallSet
# from sys.intrinsics import _type_is_eq
# from compile.reflection import get_type_name
# from caspar.storage import Storable, Vector
# from caspar.accessor import Accessor, Unique
# from utils import Variant
# from caspar.calliter import CallChildIter
# import math


# fn foo() -> KernelData[SymConfigDefault]:
#     var graph = Graph[SymConfigDefault]()
#     var x = Vector[4, reader = Unique["x"]](graph)
#     var y = Vector[4, reader = Unique["y"]](graph)
#     var z = Vector[4, writer = Unique["z"]](graph)
#     z.__setitem__[Slice(None, None, None)](x + y)
#     # z^.discard()
#     # print("slice_size", len(z[:]))
#     # alias foo = __type_of((0:2))
#     return KernelData[SymConfigDefault](graph^)

from utils.static_tuple import StaticTuple


fn slice_size(size: Int, indices: Tuple[Int, Int, Int], out ret: Int):
    var start, end, step = indices
    ret = abs(end - start) // abs(step)
    debug_assert(ret >= 0, "Slice size has to be non-negative")


struct SliceInfo[target_size: Int, slice: Slice]:
    alias indices = slice.indices(target_size)
    alias size = slice_size(target_size, Self.indices)
    alias range = range(Self.indices[0], Self.indices[1], Self.indices[2])


@register_passable("trivial")
struct MyVec[size: Int]:
    var data: StaticTuple[Float32, size]

    fn __init__(out self):
        self.data = StaticTuple[Float32, size]()

    @always_inline
    fn __getitem__[
        sl: Slice,
    ](self, out ret: MyVec[size = SliceInfo[size, sl].size]):
        ret = MyVec[size = SliceInfo[size, sl].size]()
        print("Getting with vector of size ", size, " with ", sl)

    @always_inline
    fn __setitem__[
        sl: Slice,
        other_size: Int,
    ](mut self, val: MyVec[other_size]):
        constrained[
            other_size == SliceInfo[size, sl].size,
            (
                "Slice size mismatch, target size is "
                + String(SliceInfo[size, sl].size)
                + ", but got "
                + String(other_size)
            ),
        ]()
        print("Setting with vector of size ", size, " with ", sl)


fn main() raises:
    var a = MyVec[3]()
    var b = MyVec[3]()
    var c = MyVec[10]()

    var d = c[-1:-8:-2]  # Works!

    a.__setitem__[:3](b)  # Works!
    # a[:3] = b
    # error: cannot implicitly convert 'MyVec[3]' value to 'MyVec[slice_size(3, Slice(Optional(None), Optional(3), Optional(None)).indices(3))]'

    c.__setitem__[:3](b)  # Works!
    c.__setitem__[:3](b[:])  # Works!
    # c[:3] = b
    # eerror: cannot implicitly convert 'MyVec[3]' value to 'MyVec[slice_size(10, Slice(Optional(None), Optional(3), Optional(None)).indices(10))]'

    b.__setitem__[::-1](c[1:7:2])  # Works!
    b[::-1] = c[1:7:2]
    # error: cannot implicitly convert 'MyVec[slice_size(10, Slice(Optional(1), Optional(7), Optional(2)).indices(10))]' value to 'MyVec[slice_size(3, Slice(Optional(None), Optional(None), Optional(-1)).indices(3))]'

    # a.__setitem__[:3](b)
    # a[:3] = b.__getitem__[:]()
    # b.__setitem__[::-1](a.__getitem__[2:8:2]())  # same as b[::-1] = a[2:8:2]
    # a.__setitem__[-1:-4:-1](b)  # same as a[-1:-4:-1] = b

    # var b = a.__getitem__[::2]()
    # print(b.size)  # prints 5
    # # var c = a[::2] # error: invalid call to '__getitem__': expected at most 1 positional argument, got 2

    # kernel[foo]()
    # print(a.take[funcs.StoreFloat]().value)
    # print(sizeof[StaticString]())
    # var x = Vector[4, read=Unique]("x", graph)
    # var y = Vector[4, read=Unique]("y", graph)
    # var z: Vector[4, write=Unique] = x + y
    # print(z[1])
    # b = Vector[4, write=Unique]("x", graph)
    # print(v[0])
    # print(v[1])
