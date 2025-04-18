from utils.variant import Variant  # Import Variant from the appropriate module
from .expr import ExprRef, ExprMem, Expr, ExprId
from memory import UnsafePointer
from .system import SystemBase
from .func_types import FuncSet, FuncT


@value
struct CallMem[funcSet: FuncSet](CollectionElement):
    alias dataT = Variant[String, Int, NoneType]

    alias ExprMem = ExprMem[funcSet]
    # alias Expr = Expr[funcSet, _]

    var func_id: Int
    var args: List[ExprId]
    var outs: List[Self.ExprMem]
    var data: Self.dataT

    @staticmethod
    fn to[
        funcT: FuncT
    ](out self: Self, owned args: List[Self.ExprRef], data: Self.dataT = None,):
        alias n_args = funcSet.get_n_args[funcT]()
        alias n_outs = funcSet.get_n_outs[funcT]()
        debug_assert(len(args) == n_args, "Invalid number of arguments")

        self = Self(
            func_id=funcSet.get_id[funcT](),
            args=args,
            outs=List[Self.ExprMem](capacity=n_outs),
            data=data,
        )

        @parameter
        for i in range(n_outs):
            self.outs.append(Self.ExprMem(self, i))


@register_passable
struct CallRef[funcSet: FuncSet]:
    """Represents edge in graph. Should be ref counted."""

    alias CallMem = CallMem[funcSet]

    var ptr: UnsafePointer[Self.CallMem, mut=False]

    fn __init__(out self, read call: Self.CallMem):
        self.ptr = UnsafePointer(to=call)

    fn __copyinit__(out self, other: Self):
        self.ptr = other.ptr


@register_passable("trivial")
struct Call[funcSet: FuncSet, sys: Origin, origin: Origin[False]](
    CollectionElement
):
    var ptr: Pointer[CallMem[funcSet], origin]

    fn __init__(out self, ref [origin]call: CallMem[funcSet]):
        self.ptr = Pointer(to=call)

    # fn __getitem__(
    #     self, i: Int
    # ) -> Expr[funcSet, sys, __origin_of(self.ptr[i].outs[0])]:
    #     return Expr[funcSet, sys](self.ptr[i].outs[0])
