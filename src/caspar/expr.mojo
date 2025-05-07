from memory import UnsafePointer
from .sysconfig import SymConfig
from .functions import Callable, AnyFunc


struct CallStorage[config: SymConfig]:
    var ptrs: InlineArray[
        UnsafePointer[NoneType],
        config.callables.size,
        run_destructors=True,
    ]
    var counts: InlineArray[Int, config.callables.size, run_destructors=True]
    var capacities: InlineArray[Int, config.callables.size, run_destructors=True]

    fn __init__(out self):
        self.ptrs = __type_of(self.ptrs)(uninitialized=True)
        self.counts = __type_of(self.counts)(uninitialized=True)
        self.capacities = __type_of(self.capacities)(uninitialized=True)
        alias init_size = 100

        @parameter
        for i in config.callables.range():
            alias CallT = CallMem[config, config.callables.Ts[i]]
            self.ptrs[i] = UnsafePointer[CallT].alloc(init_size).bitcast[NoneType]()
            self.counts.unsafe_ptr().offset(i).init_pointee_move(0)
            self.capacities.unsafe_ptr().offset(i).init_pointee_move(init_size)

    fn __del__(owned self):
        @parameter
        for i in config.callables.range():
            alias CallT = CallMem[config, config.callables.Ts[i]]
            for j in range(self.counts[i]):
                self.ptrs[i].bitcast[CallT]().destroy_pointee()
            self.ptrs[i].free()

    fn ptr[
        FT: Callable
    ](mut self, idx: Int) -> UnsafePointer[
        CallMem[config, FT], origin = __origin_of(self.ptrs)
    ]:
        alias func_idx = Self.func_idx[FT]()
        return self.ptrs[func_idx].bitcast[CallMem[config, FT]]().offset(idx)

    fn add[
        FT: Callable, *ArgTs: Evaluable
    ](mut self, func: FT, owned args: VariadicPack[True, _, Evaluable, *ArgTs]):
        alias func_idx = Self.func_idx[FT]()
        debug_assert(
            self.counts[func_idx] < self.capacities[func_idx],
            "CallStorage is full for function type",
        )
        alias CallT = CallMem[config, FT]
        self.ptr[FT](self.counts[func_idx]).init_pointee_copy(CallT(func, List[Int]()))
        self.counts[func_idx] += 1

    @staticmethod
    @parameter
    fn func_idx[FT: Callable](val: Int = 2) -> Int:
        return config.callables.func_to_idx[FT]()

    fn count[FT: Callable](self) -> Int:
        alias func_idx = Self.func_idx[FT]()
        return self.counts[func_idx]

    fn capacity[FT: Callable](self) -> Int:
        alias func_idx = Self.func_idx[FT]()
        return self.capacities[func_idx]


struct GraphMem[config: SymConfig]:
    var calls: CallStorage[config]
    var refcount: Int

    fn __init__(out self):
        self.calls = CallStorage[config]()
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

    fn add_call[
        FT: Callable,
        *ArgTs: Evaluable,
    ](self, owned func: FT, owned *args: *ArgTs) -> Call[config, FT]:
        self[].calls.add[FT](func^, args^)
        return Call[config, FT](
            self,
            self[].calls.count[FT]() - 1,
        )
        # return Call[config](self, len(self[].calls) - 1)


@value
@register_passable("trivial")
struct ArgIdx:
    var call: Int
    var out: Int


@value
struct CallMem[config: SymConfig, FuncT: Callable]:
    var func: FuncT
    var args: List[Int]

    # fn __init__(
    #     out self,
    #     owned func: FuncT,
    #     owned args: VariadicListMem[Expr[config]],
    # ):
    #     self.func = func^
    #     self.args = List[ArgIdx](capacity=len(args))
    # for arg in args:
    #     self.args.append(arg[].idx)


@value
@register_passable
struct Call[config: SymConfig, FuncT: Callable]:
    var graph: GraphRef[config]
    var idx: Int

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Call[config, AnyFunc[config]], other: Call[config, FT]):
        self.graph = other.graph
        self.idx = other.idx

    # fn func(self) -> ref [self.graph[].calls[self.idx].func] CallableVariant[config]:
    #     return self.graph[].calls[self.idx].func

    # fn outs(self, idx: Int) -> Expr[config]:
    #     return Expr[config](self, idx)

    # fn args(self, idx: Int) -> Expr[config]:
    #     var expr = self.graph[].calls[self.idx].args[idx]
    #     return Expr[config](Call[config](self.graph, expr.call), expr.out)

    # fn write_to[W: Writer](self, mut writer: W):
    #     self.func().write_call(self, writer)


trait Evaluable:
    ...


@value
@register_passable
struct Expr[config: SymConfig, FuncT: Callable](Evaluable):
    var call: Call[config, FuncT]
    var idx: Int

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Expr[config, AnyFunc[config]], other: Expr[config, FT]):
        self.call = other.call
        self.idx = other.idx

    fn __getitem__[name: StringLiteral["graph".value]](self) -> GraphRef[config]:
        return self.call.graph


#     var graph: GraphRef[config]
#     var idx: ArgIdx

#     fn __init__(out self, call: Call[config], idx: Int):
#         self.graph = call.graph
#         self.idx = ArgIdx(call.idx, idx)

#     fn call(self) -> Call[config]:
#         return Call[config](self.graph, self.idx.call)

#     fn args(self, idx: Int) -> Expr[config]:
#         return Expr(self.graph, self.graph[].calls[self.idx.call].args[idx])

#     fn write_to[W: Writer](self, mut writer: W):
#         self.call().write_to(writer)
#         if self.call().func().n_outs() > 1:
#             writer.write("[", self.idx.out, "]")

#     fn __add__(self, other: Self) -> Self:
#         return self.graph.add_call(Add(), self, other).outs(0)
