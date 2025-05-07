from memory import UnsafePointer
from sys import sizeof
from .sysconfig import SymConfig
from .functions import Callable, AnyFunc
from sys.intrinsics import _type_is_eq

alias StackList = List


@register_passable("trivial")
struct Index[T: StringLiteral](Indexer):
    var value: Int

    @implicit
    fn __init__(out self, value: Int):
        self.value = value

    @always_inline
    fn __index__(self) -> __mlir_type.index:
        return self.value.__index__()

    @always_inline
    fn __int__(self) -> Int:
        return self.value

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    @always_inline
    fn __req__(self, other: Self) -> Bool:
        return self.value == other.value


alias CallIdx = Index["callmem"]
alias ExprIdx = Index["exprmem"]
alias OutIdx = Index["output"]
alias FuncTypeIdx = Index["functype"]


struct CallStorage[config: SymConfig]:
    var ptrs: InlineArray[
        UnsafePointer[Byte],
        config.callables.size,
        run_destructors=True,
    ]
    var counts: InlineArray[Int, config.callables.size, run_destructors=True]
    var capacities: InlineArray[
        Int, config.callables.size, run_destructors=True
    ]
    var strides: InlineArray[Int, config.callables.size, run_destructors=True]

    fn __init__(out self):
        self.ptrs = __type_of(self.ptrs)(uninitialized=True)
        self.counts = __type_of(self.counts)(uninitialized=True)
        self.capacities = __type_of(self.capacities)(uninitialized=True)
        self.strides = __type_of(self.strides)(uninitialized=True)
        alias init_size = 100

        @parameter
        for i in config.callables.range():
            alias CallT = CallMem[config, config.callables.Ts[i]]
            self.ptrs[i] = UnsafePointer[CallT].alloc(init_size).bitcast[Byte]()
            self.counts.unsafe_ptr().offset(i).init_pointee_move(0)
            self.capacities.unsafe_ptr().offset(i).init_pointee_move(init_size)
            self.strides.unsafe_ptr().offset(i).init_pointee_move(
                sizeof[CallT]()
            )

    fn __del__(owned self):
        @parameter
        for i in config.callables.range():
            alias CallT = CallMem[config, config.callables.Ts[i]]
            for j in range(self.counts[i]):
                self.ptrs[i].bitcast[CallT]().destroy_pointee()
            self.ptrs[i].free()

    fn ptr[
        FT: Callable
    ](mut self, idx: CallIdx) -> UnsafePointer[
        CallMem[config, FT], origin = __origin_of(self.ptrs)
    ]:
        alias call_idx = Self.call_idx[FT]()
        return self.ptrs[call_idx].bitcast[CallMem[config, FT]]().offset(idx)

    fn ptr(
        mut self, func_type: FuncTypeIdx, idx: CallIdx
    ) -> UnsafePointer[
        CallMem[config, AnyFunc], origin = __origin_of(self.ptrs)
    ]:
        return (
            self.ptrs[func_type]
            .offset(Int(idx) * self.strides[func_type])
            .bitcast[CallMem[config, AnyFunc]]()
        )

    fn add[FT: Callable](mut self, owned call_mem: CallMem[config, FT]):
        alias call_idx = Self.call_idx[FT]()
        debug_assert(
            self.counts[call_idx] < self.capacities[call_idx],
            "CallStorage is full for function type",
        )
        self.ptr[FT](self.counts[call_idx]).init_pointee_copy(call_mem^)
        self.counts[call_idx] += 1

    @staticmethod
    @parameter
    fn call_idx[FT: Callable]() -> Int:
        return config.callables.func_to_idx[FT]()

    fn count[FT: Callable](self) -> Int:
        alias call_idx = Self.call_idx[FT]()
        return self.counts[call_idx]

    fn capacity[FT: Callable](self) -> Int:
        alias call_idx = Self.call_idx[FT]()
        return self.capacities[call_idx]


struct GraphMem[config: SymConfig]:
    var calls: CallStorage[config]
    var exprs: List[ExprMem[config]]
    var refcount: Int

    fn __init__(out self):
        self.calls = CallStorage[config]()
        self.exprs = List[ExprMem[config]]()
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
        debug_assert(
            initialize, "GraphRef should be initialized with initialize=True"
        )
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
    ](self, owned func: FT, owned *args: Expr[config, AnyFunc]) -> Call[
        config, FT
    ]:
        var arglist = StackList[ExprIdx](capacity=len(args))
        for arg in args:
            arglist.append(arg[].idx)

        var outlist = StackList[ExprIdx](capacity=func.n_outs())
        for i in range(func.n_outs()):
            outlist.append(len(self[].exprs))
            self[].exprs.append(
                ExprMem[config](
                    config.callables.func_to_idx[FT](),
                    self[].calls.count[FT](),
                    i,
                )
            )

        self[].calls.add[FT](CallMem[config, FT](arglist, outlist, func))

        return Call[config, FT](self, self[].calls.count[FT]() - 1)


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
        constrained[config.callables.supports[FT](), "Type not supported"]()
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
            for i in config.callables.range():
                if self[].func_type == i:
                    var view = self.view[config.callables.Ts[i]]()
                    return view.call.func.write_call(view.call, writer)

        else:
            self.call.write_to(writer)

    fn view[FT: Callable](self) -> Expr[config, FT]:
        debug_assert(
            self[].func_type == config.callables.func_to_idx[FT](),
            "Function type mismatch",
        )
        return Expr[config, FT](self.graph, self.idx)
