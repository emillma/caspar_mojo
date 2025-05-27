from .graph import Graph, CallMem, ValMem
from .graph_utils import CallIdx, ValIdx, OutIdx, FuncTypeIdx, StackList
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
    ) -> ref [self.graph[].get_callmem(self)] CallMem[FuncT, config]:
        return self.graph[].get_callmem[FuncT](self)

    fn args(self, idx: ValIdx) -> Val[AnyFunc, config, origin]:
        return Val[AnyFunc, config, origin](self.graph, self[].args[idx])

    fn __getattr__[name: StringLiteral["func".value]](self) -> ref [self[].func] FuncT:
        return self[].func

    fn __getitem__(self, idx: Int) -> Val[FuncT, config, origin]:
        return self.outs(idx)

    fn outs(self, idx: Int) -> Val[FuncT, config, origin]:
        return Val[FuncT, config, origin](self.graph, self[].outs[idx])

    fn write_to[W: Writer](self, mut writer: W):
        self.func.write_call(self, writer)


trait CasparElement(Writable & Movable & Copyable):
    fn as_val(self, graph: Graph) -> Val[AnyFunc, graph.config, __origin_of(graph)]:
        ...


@value
@register_passable
struct Val[FuncT: Callable, config: SymConfig, origin: ImmutableOrigin](CasparElement):
    var graph: Pointer[Graph[config], origin]
    var idx: ValIdx

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Val[AnyFunc, config, origin], other: Val[FT, config, origin]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ref [self.graph[].get_valmem(self)] ValMem[config]:
        return self.graph[].get_valmem(self)

    fn __getattr__[
        name: StringLiteral["call".value]
    ](self) -> Call[FuncT, config, origin]:
        return Call[FuncT, config, origin](self.graph, self[].call_idx)

    fn args(self, idx: Int) -> Val[AnyFunc, config, origin]:
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

    fn view[FT: Callable](self) -> Val[FT, config, origin]:
        debug_assert(
            self[].call_idx.type == config.funcs.func_to_idx[FT](),
            "Function type mismatch",
        )
        return Val[FT, config](self.graph, self.idx)

    fn as_val(self, graph: Graph) -> Val[AnyFunc, graph.config, __origin_of(graph)]:
        constrained[self.config == graph.config, "Graph mismatch"]()
        # TODO: transfer to other graph if necessary

        return rebind[Val[AnyFunc, graph.config, __origin_of(graph)]](self)
