from .graph import Graph, CallMem, ValMem, LockToken
from .collections import CallIdx, ValIdx, OutIdx, IndexList
from .sysconfig import SymConfig, RunConfig
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat

from sys.intrinsics import _type_is_eq


@value
@register_passable
struct Call[config: RunConfig](KeyElement, Writable):
    var graph: Pointer[Graph[config.sym], config.origin]
    var idx: CallIdx

    @implicit
    fn __init__[FT: Callable](out self: Call[config], other: Call[config]):
        constrained[config.sym.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(
        self,
    ) -> ref [self.graph[]._core[self.idx]] CallMem[config.sym]:
        return self.graph[]._core[self.idx]

    fn arg(self, idx: ValIdx) -> Val[config]:
        return Val[config](self.graph, self[].args[idx])

    fn func(self) -> ref [self[].func] __type_of(self[].func):
        return self[].func

    fn __getitem__(self, idx: Int) -> Val[config]:
        return self.out(idx)

    fn out(self, idx: Int) -> Val[config]:
        return Val[config](self.graph, self[].outs[idx])

    fn write_to[W: Writer](self, mut writer: W):
        @parameter
        for i in range(len(VariadicList(config.sym.func_types))):
            if i == Int(self.func().type_idx()):
                alias T = config.sym.func_types[i]
                self.func()[T].write_call(self, writer)

    fn __eq__(self, other: Self) -> Bool:
        return self.graph == other.graph and self.idx == other.idx

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return hash(self[])


@value
@register_passable
struct Val[config: RunConfig]:
    var graph: Pointer[Graph[config.sym], config.origin]
    var idx: ValIdx

    @implicit
    fn __init__[FT: Callable](out self: Val[config], other: Val[config]):
        constrained[config.sym.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ref [self.graph[]._core[self.idx]] ValMem[config.sym]:
        return self.graph[]._core[self.idx]

    fn call(self) -> Call[config]:
        return Call[config](self.graph, self[].call)

    # fn args(self, idx: Int) -> Val[config, origin]:
    #     return self.call.args(idx)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.call())
        if self[].out_idx != 0:
            writer.write("[", Int(self[].out_idx), "]")

    fn as_val(self, graph: Graph, token: LockToken) -> Val[graph.config, config.origin]:
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
