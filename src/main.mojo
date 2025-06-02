from caspar import funcs
from caspar.graph import Graph
from caspar.graph_core import GraphCore
from caspar.val import Val, Call, CasparElement
from caspar.funcs import AnyFunc
from caspar.context import KernelData, make_kernel, Args

from gpu import thread_idx, block_idx, global_idx, warp, barrier

from gpu.host import DeviceContext, Attribute

# from caspar.storage import ValStorage
from sys import sizeof, alignof
from memory import UnsafePointer

# from caspar.val import Val, GraphRef
from caspar.sysconfig import SymConfigDefault, FuncCollectionDefault

from caspar.collections import CallSet
from sys.intrinsics import _type_is_eq


fn foo() -> KernelData[SymConfigDefault]:
    var graph = Graph[SymConfigDefault]()
    var read_x = graph.add_call(funcs.ReadValue[1](0, 0))
    var read_y = graph.add_call(funcs.ReadValue[1](1, 0))
    var get_z = graph.add_call(funcs.Add(), read_x[0], read_y[0])
    var write_z = graph.add_call(funcs.WriteValue[1](2, 0), get_z[0])
    return KernelData[SymConfigDefault](
        order=[[read_x.idx, read_y.idx, get_z.idx, write_z.idx]],
        regmap={read_x[0].idx: 0, read_y[0].idx: 1, get_z[0].idx: 1},
        graph=graph^.take_core(),
    )


fn testkernel(x: UnsafePointer[Float32], y: UnsafePointer[Float32]):
    # alias idx = global_idx.x
    y[global_idx.x] = x[global_idx.x] + 1.0


fn main() raises:
    var ctx = DeviceContext()
    alias n = 1000000
    var x = ctx.enqueue_create_buffer[DType.float32](n)
    var y = ctx.enqueue_create_buffer[DType.float32](n)
    ctx.enqueue_memset(x, 100)
    var testkernel_ = ctx.compile_function[func=testkernel]()
    print(testkernel_.get_attribute(Attribute.CONST_SIZE_BYTES))
    # ctx.enqueue_launch(
    #     testkernel_,
    #     grid_size=(n // 256 + 1, 1, 1),
    #     block_size=(256, 1, 1),
    #     args=(x, y),
    # )

    lhs_host_buffer = ctx.enqueue_create_host_buffer[DType.float32](100)
    rhs_host_buffer = ctx.enqueue_create_host_buffer[DType.float32](100)
    ctx.synchronize()
    alias kernel = make_kernel[foo()]()
    kernel()
