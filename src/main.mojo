# from caspar.compile import Kernel, Arg

from caspar import accessors
from caspar.graph import Graph

from caspar.storage import Vector
from caspar import funcs
from sys.intrinsics import _type_is_eq
from caspar.compile import kernel, KernelDesc
from caspar.kernel_args import PtrArg


fn foo() -> KernelDesc:
    # fn foo():
    var graph = Graph()
    var x = Vector[4]("x", graph)
    var _ = Vector[4]("__", graph)
    var y = Vector[4]("y", graph)

    return graph.make_kernel(
        accessors.ReadUnique(x),
        accessors.ReadUnique(y),
        accessors.WriteUnique(x + y),
    )


trait MyThing:
    ...


fn main():
    print("start")
    var x = InlineArray[Float32, 4](1, 3, 2, 3)
    var y = InlineArray[Float32, 4](2, 3, -8, 9)
    var z = InlineArray[Float32, 4](fill=-1)
    var px = PtrArg(x)
    var py = PtrArg(y)
    var pz = PtrArg(z)
    print(px.ptr, py.ptr, pz.ptr)
    kernel[foo](px, py, pz)
    print(y[0])
    for i in range(4):
        print(x[i], y[i], z[i])

    # print(x.unsafe_ptr()[], y.unsafe_ptr()[], z.unsafe_ptr()[])

    print("end")
    # accessors.ReadUnique[Vector[4]]
