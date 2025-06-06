from .graph import Graph, CallMem, ValMem, LockToken
from .collections import CallIdx, ValIdx, OutIdx, IndexList
from .sysconfig import SymConfig
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat

from sys.intrinsics import _type_is_eq


@value
@register_passable
struct Call[config: SymConfig, origin: ImmutableOrigin](KeyElement):
    var graph: Pointer[Graph[config], origin]
    var idx: CallIdx

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Call[config, origin], other: Call[config, origin]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(
        self,
    ) -> ref [self.graph[].get_callmem(self)] CallMem[config]:
        return self.graph[].get_callmem(self)

    fn arg(self, idx: ValIdx) -> Val[config, origin]:
        return Val[config, origin](self.graph, self[].args[idx])

    fn func(self) -> ref [self[].func] config.FuncVariant:
        return self[].func

    fn __getitem__(self, idx: Int) -> Val[config, origin]:
        return self.out(idx)

    fn out(self, idx: Int) -> Val[config, origin]:
        return Val[config, origin](self.graph, self[].outs[idx])

    fn write_to[W: Writer](self, mut writer: W):
        @parameter
        for i in range(len(VariadicList(config.funcs.Ts))):
            if i == Int(self.func().type_idx()):
                alias T = config.funcs.Ts[i]
                self.func()[T].write_call(self, writer)

    fn __eq__(self, other: Self) -> Bool:
        return self.graph == other.graph and self.idx == other.idx

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return hash(self[])


trait CasparElement(Writable & Movable & Copyable):
    fn as_val(
        self, graph: Graph, token: LockToken
    ) -> Val[graph.config, __origin_of(graph)]:
        ...


@value
@register_passable
struct Val[config: SymConfig, origin: ImmutableOrigin](CasparElement):
    var graph: Pointer[Graph[config], origin]
    var idx: ValIdx

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Val[config, origin], other: Val[config, origin]):
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ref [self.graph[].get_valmem(self)] ValMem[config]:
        return self.graph[].get_valmem(self)

    fn call(self) -> Call[config, origin]:
        return Call[config, origin](self.graph, self[].call)

    # fn args(self, idx: Int) -> Val[config, origin]:
    #     return self.call.args(idx)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.call())
        if self[].out_idx != 0:
            writer.write("[", Int(self[].out_idx), "]")

    fn as_val(
        self, graph: Graph, token: LockToken
    ) -> Val[graph.config, __origin_of(graph)]:
        if self.graph[] is graph:
            return rebind[Val[graph.config, __origin_of(graph)]](self)
        else:
            debug_assert(False, "Graph mismatch")
            return rebind[Val[graph.config, __origin_of(graph)]](self)

    fn __eq__(self, other: Self) -> Bool:
        return self.graph == other.graph and self.idx == other.idx

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return hash(self[])
