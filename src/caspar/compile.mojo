from .collections import RegIdx
from .graph import Graph
from .graph_core import GraphCore, CallIdx, ValIdx, IndexList

from memory import UnsafePointer
from utils.static_tuple import StaticTuple
from caspar.accessors import Accessor
from caspar.storage import Storable
from caspar.val import Val, Call
from caspar.kernel_args import Argument, PtrArg
from caspar.config import FuncVariant
from benchmark import keep
from compile.reflection import get_type_name
from memory import stack_allocation


struct KernelDesc(Movable):
    var graph: Graph
    var arg_keys: List[StaticString]
    var order: List[CallIdx]
    var stack_size: Int
    # var signature: List[AccessorVariant]

    fn __init__(out self, owned graph: Graph, owned arg_keys: List[StaticString]):
        self.graph = graph^
        self.arg_keys = arg_keys^
        self.order = [i for i in range(len(self.graph._core.calls))]
        self.stack_size = len(self.graph._core.vals)


struct Kernel[desc_fn: fn () -> KernelDesc, *ArgTs: Argument]:
    alias desc = desc_fn()

    @staticmethod
    fn inner(owned *args: *ArgTs):
        alias ContextT = Context[Self.desc.stack_size, *ArgTs]
        var context = ContextT(args^)

        @parameter
        for i in range(len(Self.desc.order)):
            alias callmem = Self.desc.graph._core[Self.desc.order[i]]
            alias FT = FuncVariant.Ts[callmem.func.type_idx()]
            alias func = callmem.func[FT]
            FT.evaluate[callmem.args, callmem.outs, func.data()](context)


@register_passable
struct ArgStorage[*Ts: Argument](Sized):
    var storage: __mlir_type[`!kgen.pack<:!kgen.variadic<`, Argument, `> `, Ts, `>`]

    fn __init__(out self, owned *storage: *Ts):
        self = Self(storage=storage^)

    fn __init__(out self, owned storage: VariadicPack[_, _, Argument, *Ts]):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self.storage))

        @parameter
        for i in range(len(VariadicList(Ts))):
            UnsafePointer(to=storage[i]).move_pointee_into(UnsafePointer(to=self[i]))
        __disable_del storage

    @always_inline("nodebug")
    fn __getitem__[idx: Int](ref self) -> ref [self] Ts[idx]:
        var storage_kgen_ptr = UnsafePointer(to=self.storage).address
        var elt_kgen_ptr = __mlir_op.`kgen.pack.gep`[index = idx.value](
            storage_kgen_ptr
        )
        return UnsafePointer(elt_kgen_ptr)[]

    fn __len__(self) -> Int:
        return len(VariadicList(Ts))


@register_passable
struct Context[stack_size: Int, *Ts: Argument]:
    var args: ArgStorage[*Ts]
    var stack: StaticTuple[Float32, stack_size]

    fn __init__(out self, owned storage: VariadicPack[_, _, Argument, *Ts]):
        self.args = ArgStorage(storage^)
        self.stack = StaticTuple[Float32, stack_size]()

    # @always_inline
    fn arg[idx: Int](self) -> ref [self.args] Ts[idx]:
        return self.args[idx]

    # @always_inline
    fn get[idx: ValIdx](self) -> Float32:
        return self.stack[idx.value]

    # @always_inline
    fn set[idx: ValIdx](mut self, val: Float32):
        self.stack[idx.value] = val


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
