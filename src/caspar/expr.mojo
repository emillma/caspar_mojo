from .graph import Graph, CallMem, ExprMem
from .graph_utils import CallIdx, ExprIdx, OutIdx, FuncTypeIdx, StackList
from .sysconfig import SymConfig
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat

from sys.intrinsics import _type_is_eq


@value
@register_passable
struct Call[FuncT: Callable, config: SymConfig, origin: ImmutableOrigin]:
    var graph: Pointer[Graph[config], origin]
    var idx: CallIdx

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Call[AnyFunc, config, origin], other: Call[FT, config, origin]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(
        self,
    ) -> ref [self.graph[].calls] CallMem[FuncT, config]:
        return (
            self.graph[]
            .calls.ptr[self.FuncT](self.idx)
            .bitcast[CallMem[FuncT, config]]()[]
        )

    fn args(self, idx: ExprIdx) -> Expr[AnyFunc, config, origin]:
        return Expr[AnyFunc, config, origin](self.graph, self[].args[idx])

    fn __getattr__[name: StringLiteral["func".value]](self) -> ref [self[].func] FuncT:
        return self[].func

    fn __getitem__(self, idx: Int) -> Expr[FuncT, config, origin]:
        return self.outs(idx)

    fn outs(self, idx: Int) -> Expr[FuncT, config, origin]:
        return Expr[FuncT, config, origin](
            self.graph, self.graph[].calls.get[FuncT](self.idx).outs[idx]
        )

    fn write_to[W: Writer](self, mut writer: W):
        self.func.write_call(self, writer)


trait CasparElement(Writable & Movable & Copyable):
    fn as_expr[
        origin: ImmutableOrigin
    ](self, ref [origin]graph: Graph) -> Expr[AnyFunc, graph.config, origin]:
        ...


@value
@register_passable
struct Expr[FuncT: Callable, config: SymConfig, origin: ImmutableOrigin](CasparElement):
    var graph: Pointer[Graph[config], origin]
    var idx: ExprIdx

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Expr[AnyFunc, config, origin], other: Expr[FT, config, origin]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ref [self.graph[].exprs[self.idx]] ExprMem[config]:
        return self.graph[].exprs[self.idx]

    fn __getattr__[
        name: StringLiteral["call".value]
    ](self) -> Call[FuncT, config, origin]:
        return Call[FuncT, config, origin](self.graph, self[].call_idx)

    fn args(self, idx: Int) -> Expr[AnyFunc, config, origin]:
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

    fn view[FT: Callable](self) -> Expr[FT, config, origin]:
        debug_assert(
            self[].call_idx.type == config.funcs.func_to_idx[FT](),
            "Function type mismatch",
        )
        return Expr[FT, config](self.graph, self.idx)

    fn as_expr[
        origin_other: ImmutableOrigin
    ](self, ref [origin_other]graph: Graph) -> Expr[
        AnyFunc, graph.config, origin_other
    ]:
        constrained[self.config == graph.config, "Graph mismatch"]()
        # TODO: transfer to other graph if necessary
        # debug_assert(self.graph == Pointer(to=graph), "Graph mismatch"

        return rebind[Expr[AnyFunc, graph.config, origin_other]](self)
