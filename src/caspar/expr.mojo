from memory import UnsafePointer
from .call import CallRef, CallMem
from .func_types import FuncSet, FuncT


@register_passable
struct ExprMem[funcSet: FuncSet](CollectionElement):
    var call: CallRef[funcSet]
    var idx: Int
    var uses: Int

    fn __init__(out self, mut call: CallMem[funcSet], idx: Int):
        self.call = CallRef[funcSet](call)
        self.idx = idx
        self.uses = 0

    fn __copyinit__(out self, other: Self):
        self.call = other.call
        self.idx = other.idx
        self.uses = 0


@register_passable("trivial")
struct ExprId:
    var func: Int
    var out: Int

    fn __init__(out self, func: Int, out: Int = 0):
        self.func = func
        self.out = out


@register_passable
struct ExprRef[funcSet: FuncSet](CollectionElement):
    """Represents edge in graph. Should be ref counted."""

    var ptr: UnsafePointer[ExprMem[funcSet]]

    @implicit
    fn __init__(out self, expr: Expr[funcSet]):
        self.ptr = UnsafePointer(to=expr.ptr[])

    fn __copyinit__(out self, other: Self):
        self.ptr = other.ptr


@register_passable("trivial")
struct Expr[funcSet: FuncSet, sys: Origin, origin: Origin[False]](
    CollectionElement
):
    var ptr: Pointer[ExprMem[funcSet], origin]

    fn __init__(out self, ref [origin]expr: ExprMem[funcSet]):
        self.ptr = Pointer(to=expr)
