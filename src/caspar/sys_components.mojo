from .func_types import FuncT, FuncVariant
from .sys import System


@value
struct CallMem:
    var func: FuncVariant
    var arg_ids: List[ExprId]

    fn __init__[
        origin: MutableOrigin
    ](
        out self,
        func: FuncVariant,
        args: VariadicListMem[Expr[origin]],
        call_id: Int,
    ):
        self.func = func
        self.arg_ids = List[ExprId](capacity=len(args))
        for arg in args:
            self.arg_ids.append(arg[].id)


@value
struct ExprMem:
    var func: FuncVariant
    var call_id: Int


@value
@register_passable("trivial")
struct ExprId:
    var func: Int
    var out: Int


@value
struct Expr[sys_origin: MutableOrigin](Writable):
    var sysref: Pointer[System, sys_origin]
    var id: ExprId

    fn __init__(
        out self, ref [sys_origin]sys: System, call_id: Int, out_idx: Int
    ):
        self.sysref = Pointer(to=sys)
        self.id = ExprId(call_id, out_idx)

    fn __str__(self) -> String:
        return String(self.sysref[].calls.__len__())
        # return f"Expr({self.sysref}, {self.id})"

    fn write_to[T: Writer](self, mut writer: T):
        ("caspar").write_to(writer)
