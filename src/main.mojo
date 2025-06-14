# from caspar.compile import Kernel, Arg

from caspar import accessors
from caspar.graph import Graph

from caspar.storage import Vector
from caspar import funcs
from sys.intrinsics import _type_is_eq
from caspar.compile import Kernel, KernelDesc
from caspar.kernel_args import PtrArg

from gpu.host import DeviceContext
from gpu.id import block_idx, thread_idx
from pathlib import Path
from compile.reflection import get_type_name
from benchmark import keep
from python import Python




fn foo() -> KernelDesc:
    # fn foo():
    var graph = Graph()
    var x = Vector[4]("x", graph)
    var y = Vector[4]("y", graph)
    var z = x + y
    return KernelDesc(
        accessors.ReadUnique(x),
        accessors.ReadUnique(y),
        accessors.WriteUnique(z),
    )


def main():
    # alias hello = bar()
    var array = Python.list(1, 2, 3)
    print(array)

    var x = InlineArray[Float32, 4](1, 3, 2, 3)
    var y = InlineArray[Float32, 4](2, 3, -8, 9)
    var z = InlineArray[Float32, 4](fill=-1)

    var px = PtrArg(x)
    var py = PtrArg(y)
    var pz = PtrArg(z)
    alias mykernel = Kernel[foo, PtrArg[4], PtrArg[4], PtrArg[4]].inner
    mykernel(px, py, pz)  # run on CPU
    for i in range(4):
        print(x[i], y[i], z[i])

    var ctx = DeviceContext()
    kernel = ctx.compile_function[
        mykernel, dump_asm = Path("file.ptx"), _ptxas_info_verbose=True
    ]()

#     print("end")
