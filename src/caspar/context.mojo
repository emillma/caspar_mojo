from .graph_core import GraphCore, CallIdx, ValIdx
from .collections import RegIdx
from caspar.sysconfig import SymConfig
from compile.reflection import get_type_name
from utils.static_tuple import StaticTuple
from memory import UnsafePointer


trait Context:
    ...


struct CpuContext:
    ...


struct KernelData[config: SymConfig]:
    var graph: GraphCore[config]
    var order: List[List[CallIdx]]
    var regmap: Dict[ValIdx, RegIdx]

    fn __init__(
        out self,
        owned graph: GraphCore[config],
        owned order: List[List[CallIdx]],
        owned regmap: Dict[ValIdx, RegIdx],
    ):
        self.graph = graph^
        self.order = order^
        self.regmap = regmap^


@register_passable
struct Args[*Ts: AnyType]:
    var storage: __mlir_type[`!kgen.pack<:!kgen.variadic<`, AnyType, `> `, Ts, `>`]

    @always_inline("nodebug")
    fn __init__(out self, owned *args: *Ts):
        self = Self(storage=args^)

    @always_inline("nodebug")
    fn __getitem__[idx: Int](ref self) -> ref [self] Ts[idx.value]:
        var storage_kgen_ptr = UnsafePointer(to=self.storage).address
        var elt_kgen_ptr = __mlir_op.`kgen.pack.gep`[index = idx.value](
            storage_kgen_ptr
        )
        return UnsafePointer(elt_kgen_ptr)[]

    @always_inline("nodebug")
    fn __init__(
        out self,
        *,
        owned storage: VariadicPack[_, _, Copyable & Movable, *Ts],
    ):
        """Construct the tuple from a low-level internal representation.

        Args:
            storage: The variadic pack storage to construct from.
        """

        # Mark 'self.storage' as being initialized so we can work on it.
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self.storage))

        # Move each element into the tuple storage.
        @parameter
        for i in range(Self.__len__()):
            UnsafePointer(to=storage[i]).move_pointee_into(UnsafePointer(to=self[i]))

        # Do not destroy the elements when 'storage' goes away.
        __disable_del storage

    # fn __init__(out self, owned args: StaticTuple[*Ts]):
    #     self.args = args^

    # fn __getitem__(self, idx: Int) -> AnyType:
    #     return self.args[idx]

    # fn __len__(self) -> Int:
    #     return len(self.args)


fn make_kernel[config: SymConfig, //, data: KernelData[config]]() -> fn ():
    fn inner():
        @parameter
        for i in range(len(data.order)):

            @parameter
            for j in range(len(data.order[i])):
                alias callidx = data.order[i][j]
                alias name = config.funcs.Ts[Int(callidx.type)].info.fname
                print("CallIdx:", name)

    return inner
