from .graph import GraphRef, CallMem, ExprMem
from .graph_utils import CallIdx, ExprIdx, OutIdx, FuncTypeIdx, StackList
from .sysconfig import SymConfig
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat

from sys.intrinsics import _type_is_eq


@value
@register_passable
struct Call[FuncT: Callable, config: SymConfig]:
    var graph: GraphRef[config]
    var idx: CallIdx

    @implicit
    fn __init__[FT: Callable](out self: Call[AnyFunc, config], other: Call[FT, config]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(
        self,
    ) -> ref [self.graph[].calls.ptr(self.idx)[]] CallMem[FuncT, config]:
        return self.graph[].calls.ptr(self.idx).bitcast[CallMem[FuncT, config]]()[]

    fn args(self, idx: ExprIdx) -> Expr[AnyFunc, config]:
        return Expr[AnyFunc, config](self.graph, self[].args[idx])

    fn __getattr__[name: StringLiteral["func".value]](self) -> ref [self[].func] FuncT:
        return self[].func

    fn __getitem__(self, idx: Int) -> Expr[FuncT, config]:
        return self.outs(idx)

    fn outs(self, idx: Int) -> Expr[FuncT, config]:
        return Expr[FuncT, config](self.graph, self[].outs[idx])

    fn write_to[W: Writer](self, mut writer: W):
        self.func.write_call(self, writer)


trait CasparElement(Writable & Movable & Copyable):
    fn as_expr(self, graph: GraphRef) -> Expr[AnyFunc, graph.config]:
        ...


@value
@register_passable
struct Expr[FuncT: Callable, config: SymConfig](CasparElement):
    var graph: GraphRef[config]
    var idx: ExprIdx

    @implicit
    fn __init__[FT: Callable](out self: Expr[AnyFunc, config], other: Expr[FT, config]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ref [self.graph[].exprs[self.idx]] ExprMem[config]:
        return self.graph[].exprs[self.idx]

    fn __getattr__[name: StringLiteral["call".value]](self) -> Call[FuncT, config]:
        return Call[FuncT, config](self.graph, self[].call_idx)

    fn args(self, idx: Int) -> Expr[AnyFunc, config]:
        return self.call.args(idx)

    fn write_to[W: Writer](self, mut writer: W):
        @parameter
        if _type_is_eq[FuncT, AnyFunc]():

            @parameter
            for i in config.funcs.range():
                if self[].call_idx.type == i:
                    var view = self.view[config.funcs.Ts[i]]()
                    return view.call.func.write_call(view.call, writer)

        else:
            self.call.write_to(writer)

    fn view[FT: Callable](self) -> Expr[FT, config]:
        debug_assert(
            self[].call_idx.type == config.funcs.func_to_idx[FT](),
            "Function type mismatch",
        )
        return Expr[FT, config](self.graph, self.idx)

    fn as_expr(self, graph: GraphRef) -> Expr[AnyFunc, graph.config]:
        constrained[self.config == graph.config, "Graph mismatch"]()
        debug_assert(self.graph is graph, "Graph mismatch")
        return rebind[Expr[AnyFunc, graph.config]](self)


@value
@register_passable("trivial")
struct Value(CasparElement):
    var data: Float64

    @implicit
    fn __init__(out self, data: Floatable):
        self.data = data.__float__()

    fn write_to[W: Writer](self, mut writer: W):
        self.data.write_to(writer)

    fn as_expr(self, graph: GraphRef) -> Expr[AnyFunc, graph.config]:
        if self.data == 0:
            return graph.add_call(StoreZero())[0]
        elif self.data == 1:
            return graph.add_call(StoreOne())[0]
        else:
            return graph.add_call(StoreFloat(self.data[0]))[0]
