from .graph import GraphRef
from .graph_utils import CallIdx, ExprIdx, OutIdx, FuncTypeIdx, StackList
from .sysconfig import SymConfig
from .functions import Callable, AnyFunc
from sys.intrinsics import _type_is_eq


@value
struct CallMem[config: SymConfig, FuncT: Callable]:
    var args: StackList[ExprIdx]
    var outs: StackList[ExprIdx]
    var func: FuncT


@register_passable
struct Call[config: SymConfig, FuncT: Callable]:
    var graph: GraphRef[config]
    var idx: CallIdx

    fn __init__(out self, graph: GraphRef[config], idx: CallIdx):
        self.graph = graph
        self.idx = idx

    fn __getitem__(
        self,
    ) -> ref [self.graph[].calls.ptr[FuncT](self.idx)[]] CallMem[config, FuncT]:
        return self.graph[].calls.ptr[FuncT](self.idx)[]

    fn args(self, idx: ExprIdx) -> Expr[config, AnyFunc]:
        return Expr[config, AnyFunc](self.graph, self[].args[idx])

    fn __getattr__[
        name: StringLiteral["func".value]
    ](self) -> ref [self[].func] FuncT:
        return self[].func

    fn __getitem__(self, idx: Int) -> Expr[config, FuncT]:
        return self.outs(idx)

    fn outs(self, idx: Int) -> Expr[config, FuncT]:
        return Expr[config, FuncT](self.graph, self[].outs[idx])

    fn write_to[W: Writer](self, mut writer: W):
        self.func.write_call(self, writer)


@value
struct ExprMem[config: SymConfig]:
    var func_type: FuncTypeIdx
    var call_idx: CallIdx
    var out_idx: OutIdx


@value
@register_passable
struct Expr[config: SymConfig, FuncT: Callable]:
    var graph: GraphRef[config]
    var idx: ExprIdx

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Expr[config, AnyFunc], other: Expr[config, FT]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ref [self.graph[].exprs[self.idx]] ExprMem[config]:
        return self.graph[].exprs[self.idx]

    fn __getattr__[
        name: StringLiteral["call".value]
    ](self) -> Call[config, FuncT]:
        return Call[config, FuncT](self.graph, self[].call_idx)

    fn args(self, idx: Int) -> Expr[config, AnyFunc]:
        return self.call.args(idx)

    fn write_to[W: Writer](self, mut writer: W):
        @parameter
        if _type_is_eq[FuncT, AnyFunc]():

            @parameter
            for i in config.funcs.range():
                if self[].func_type == i:
                    var view = self.view[config.funcs.Ts[i]]()
                    return view.call.func.write_call(view.call, writer)

        else:
            self.call.write_to(writer)

    fn view[FT: Callable](self) -> Expr[config, FT]:
        debug_assert(
            self[].func_type == config.funcs.func_to_idx[FT](),
            "Function type mismatch",
        )
        return Expr[config, FT](self.graph, self.idx)
