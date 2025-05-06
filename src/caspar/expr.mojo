from memory import UnsafePointer
from .callable import CallableVariant
from .sysconfig import SymConfig
from .functions import Symbol, Add


struct GraphMem[config: SymConfig]:
    var calls: List[CallMem[config]]
    var refcount: Int

    fn __init__(out self):
        self.calls = List[CallMem[config]]()
        self.refcount = 1

    fn add_ref(mut self):
        self.refcount += 1

    fn drop_ref(mut self) -> Bool:
        self.refcount -= 1
        debug_assert(self.refcount >= 0, "Refcount should never be negative")
        return self.refcount == 0


@register_passable
struct GraphRef[config: SymConfig]:
    var ptr: UnsafePointer[GraphMem[config]]

    fn __init__(out self, *, initialize: Bool):
        debug_assert(initialize, "GraphRef should be initialized with initialize=True")
        self.ptr = UnsafePointer[GraphMem[config]].alloc(1)
        __get_address_as_uninit_lvalue(self.ptr.address) = GraphMem[config]()

    fn __copyinit__(out self, existing: Self):
        existing[].add_ref()
        self.ptr = existing.ptr

    fn __getitem__(self) -> ref [self.ptr.origin] GraphMem[config]:
        return self.ptr[]

    fn __del__(owned self):
        if self[].drop_ref():
            self.ptr.destroy_pointee()
            self.ptr.free()

    fn __is__(self, other: Self) -> Bool:
        return self.ptr == other.ptr

    fn add_call(
        self, func: CallableVariant[config], *args: Expr[config]
    ) -> CallRef[config]:
        self[].calls.append(CallMem(func, args))
        return CallRef[config](self, len(self[].calls) - 1)


@value
@register_passable("trivial")
struct ArgIdx:
    var call: Int
    var out: Int


@value
struct CallMem[config: SymConfig]:
    var func: CallableVariant[config]
    var args: List[ArgIdx]

    fn __init__(
        out self,
        owned func: CallableVariant[config],
        args: VariadicListMem[Expr[config]],
    ):
        self.func = func^
        self.args = List[ArgIdx](capacity=len(args))
        for arg in args:
            self.args.append(arg[].idx)


@value
@register_passable
struct CallRef[config: SymConfig]:
    var graph: GraphRef[config]
    var idx: Int

    fn func(self) -> ref [self.graph[].calls[self.idx].func] CallableVariant[config]:
        return self.graph[].calls[self.idx].func

    fn outs(self, idx: Int) -> Expr[config]:
        return Expr[config](self, idx)

    fn args(self, idx: Int) -> Expr[config]:
        var expr = self.graph[].calls[self.idx].args[idx]
        return Expr[config](CallRef[config](self.graph, expr.call), expr.out)

    fn write_to[W: Writer](self, mut writer: W):
        self.func().write_call(self, writer)


@value
@register_passable
struct Expr[config: SymConfig]:
    var graph: GraphRef[config]
    var idx: ArgIdx

    fn __init__(out self, call: CallRef[config], idx: Int):
        self.graph = call.graph
        self.idx = ArgIdx(call.idx, idx)

    fn call(self) -> CallRef[config]:
        return CallRef[config](self.graph, self.idx.call)

    fn args(self, idx: Int) -> Expr[config]:
        return Expr(self.graph, self.graph[].calls[self.idx.call].args[idx])

    fn write_to[W: Writer](self, mut writer: W):
        self.call().write_to(writer)
        if self.call().func().n_outs() > 1:
            writer.write("[", self.idx.out, "]")

    fn __add__(self, other: Self) -> Self:
        return self.graph.add_call(Add(), self, other).outs(0)
