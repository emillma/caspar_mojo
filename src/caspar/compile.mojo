from .collections import RegIdx
from .graph import Graph
from .graph_core import GraphCore, CallIdx, ValIdx, IndexList

from memory import UnsafePointer
from utils.static_tuple import StaticTuple
from caspar.accessors import Accessor
from caspar.storage import Storable
from caspar.val import Val, Call
from caspar.args import ArgType, ArgKey


struct Kernel(Movable):
    var graph: Graph
    var arg_keys: List[ArgKey]
    var order: List[CallIdx]
    var stack_size: Int
    # var signature: List[AccessorVariant]

    fn __init__(out self, owned graph: Graph, arg_keys: List[ArgKey]):
        self.graph = graph
        self.arg_keys = arg_keys
        self.order = [i for i in range(len(graph._core.calls))]
        self.stack_size = len(graph._core.vals)


# fn kernel[desc_fn: fn () -> KernelData[DefaultGraphConfig]]():
#     alias desc = desc_fn()
#     var stack = StaticTuple[Float32, desc.stack_size]()

#     var x = InlineArray[Float32, 4](fill=1)
#     var y = InlineArray[Float32, 4](fill=2)
#     var z = InlineArray[Float32, 4](fill=-1)
#     var args = Args(
#         x.unsafe_ptr(),
#         y.unsafe_ptr(),
#         z.unsafe_ptr(),
#     )
#     var context = CpuContext[12](args)

#     @parameter
#     for i in range(len(desc.order)):
#         alias call = desc.graph._core[desc.order[i]]
#         alias funcvar = call.func
#         alias FT = desc.sym.func_types[funcvar.type_idx()]
#         alias func = funcvar.unsafe_get[FT]()
#         alias data = func.data()
#         FT.evaluate[args = call.args, outs = call.outs, data=data](context)

#         @parameter
#         for i in range(context.stack_size):
#             print(context.stack[i], end=", ")
#         print()
#     for i in range(4):
#         print(z[i], end=", ")
#         print()


trait Context:
    @always_inline
    fn arg[name: StaticString](self) -> UnsafePointer[Float32]:
        ...

    @always_inline
    fn get[idx: ValIdx](self) -> Float32:
        ...

    @always_inline
    fn set[idx: ValIdx](mut self, val: Float32):
        ...


# @register_passable("trivial")
# struct CpuContext[stack_size: Int](Context):
#     var args: Args
#     var stack: StaticTuple[Float32, stack_size]

#     fn __init__(out self, owned args: Args):
#         self.args = args
#         self.stack = StaticTuple[Float32, stack_size]()

#     @always_inline
#     fn arg[name: StaticString](self) -> UnsafePointer[Float32]:
#         return self.args.arg[name]()

#     @always_inline
#     fn get[idx: ValIdx](self) -> Float32:
#         return self.stack[idx]

#     @always_inline
#     fn set[idx: ValIdx](mut self, val: Float32):
#         self.stack.__setitem__[idx.value](val)


# @value
# @register_passable("trivial")
# struct Args:
#     var x: UnsafePointer[Float32]
#     var y: UnsafePointer[Float32]
#     var z: UnsafePointer[Float32]

#     @always_inline
#     fn arg[name: StaticString](self) -> UnsafePointer[Float32]:
#         @parameter
#         if name == "x":
#             return self.x
#         elif name == "y":
#             return self.y
#         elif name == "z":
#             return self.z
#         return UnsafePointer[Float32]()


# @register_passable
# struct Args[*Ts: AnyType]:
#     var storage: __mlir_type[`!kgen.pack<:!kgen.variadic<`, AnyType, `> `, Ts, `>`]

#     @always_inline("nodebug")
#     fn __init__(out self, owned *args: *Ts):
#         self = Self(storage=args^)

#     @always_inline("nodebug")
#     fn __getitem__[idx: Int](ref self) -> ref [self] Ts[idx.value]:
#         var storage_kgen_ptr = UnsafePointer(to=self.storage).address
#         var elt_kgen_ptr = __mlir_op.`kgen.pack.gep`[index = idx.value](
#             storage_kgen_ptr
#         )
#         return UnsafePointer(elt_kgen_ptr)[]

#     @always_inline("nodebug")
#     fn __init__(
#         out self,
#         *,
#         owned storage: VariadicPack[_, _, Copyable & Movable, *Ts],
#     ):
#         """Construct the tuple from a low-level internal representation.

#         Args:
#             storage: The variadic pack storage to construct from.
#         """

#         # Mark 'self.storage' as being initialized so we can work on it.
#         __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self.storage))

#         # Move each element into the tuple storage.
#         @parameter
#         for i in range(Self.__len__()):
#             UnsafePointer(to=storage[i]).move_pointee_into(UnsafePointer(to=self[i]))

#         # Do not destroy the elements when 'storage' goes away.
#         __disable_del storage

# fn __init__(out self, owned args: StaticTuple[*Ts]):
#     self.args = args^

# fn __getitem__(self, idx: Int) -> AnyType:
#     return self.args[idx]

# fn __len__(self) -> Int:
#     return len(self.args)


# fn make_kernel[config: SymConfig, //, data: KernelData[config]]() -> fn ():
#     fn inner():
#         @parameter
#         for i in range(len(data.order)):

#             @parameter
#             for j in range(len(data.order[i])):
#                 alias callidx = data.order[i][j]
#                 alias name = config.funcs.Ts[Int(callidx.type)].info.fname
#                 print("CallIdx:", name)

#     return inner
