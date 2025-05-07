from memory import UnsafePointer
from sys import sizeof
from .sysconfig import SymConfig
from .functions import Callable, AnyFunc
from sys.intrinsics import _type_is_eq

alias StackList = List


@value
@nonmaterializable(Int)
@register_passable("trivial")
struct FuncTypeIdx:
    var data: Int

    fn __int__(self) -> Int:
        return self.data


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
    ](mut self, idx: Int) -> UnsafePointer[
        CallMem[config, FT], origin = __origin_of(self.ptrs)
    ]:
        alias func_idx = Self.func_idx[FT]()
        return self.ptrs[func_idx].bitcast[CallMem[config, FT]]().offset(idx)

    fn ptr(
        mut self, func_type: Int, idx: Int
    ) -> UnsafePointer[
        CallMem[config, AnyFunc], origin = __origin_of(self.ptrs)
    ]:
        return (
            self.ptrs[func_type]
            .offset(idx * self.strides[func_type])
            .bitcast[CallMem[config, AnyFunc]]()
        )

    fn add[FT: Callable](mut self, owned call_mem: CallMem[config, FT]):
        alias func_idx = Self.func_idx[FT]()
        debug_assert(
            self.counts[func_idx] < self.capacities[func_idx],
            "CallStorage is full for function type",
        )
        self.ptr[FT](self.counts[func_idx]).init_pointee_copy(call_mem^)
        self.counts[func_idx] += 1

    @staticmethod
    @parameter
    fn func_idx[FT: Callable]() -> Int:
        return config.callables.func_to_idx[FT]()

    fn count[FT: Callable](self) -> Int:
        alias func_idx = Self.func_idx[FT]()
        return self.counts[func_idx]

    fn capacity[FT: Callable](self) -> Int:
        alias func_idx = Self.func_idx[FT]()
        return self.capacities[func_idx]


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
        var arglist = StackList[Int](capacity=len(args))
        for arg in args:
            arglist.append(arg[].idx)

        var outlist = StackList[Int](capacity=func.n_outs())
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
    var args: StackList[Int]
    var outs: StackList[Int]
    var func: FuncT

    # fn __init__(
    #     out self,
    #     owned func: FuncT,
    #     owned args: VariadicListMem[Expr[config]],
    # ):
    #     self.func = func^
    #     self.args = List[ArgIdx](capacity=len(args))
    # for arg in args:
    #     self.args.append(arg[].idx)


# @value
@register_passable
struct Call[config: SymConfig, FuncT: Callable]:
    var graph: GraphRef[config]
    var idx: Int

    fn __init__(out self, graph: GraphRef[config], idx: Int):
        self.graph = graph
        self.idx = idx

    fn __getitem__(
        self,
    ) -> ref [self.graph[].calls.ptr[FuncT](self.idx)[]] CallMem[config, FuncT]:
        return self.graph[].calls.ptr[FuncT](self.idx)[]

    fn __getattr__[
        name: StringLiteral["args".value]
    ](self) -> ref [self[].args] StackList[Int]:
        return self[].args

    fn __getattr__[
        name: StringLiteral["func".value]
    ](self) -> ref [self[].func] FuncT:
        return self[].func

    fn __getitem__(self, idx: Int) -> Expr[config, FuncT]:
        return self.outs(idx)

    fn outs(self, idx: Int) -> Expr[config, FuncT]:
        return Expr[config, FuncT](self.graph, self[].outs[idx])

    # fn args(self) -> ref [self[].args] StackList[Int]:
    #     return self[].args

    # fn args(self, idx: Int) -> Expr[config, AnyFunc]:
    #     return Expr[config, AnyFunc](self.graph, self.args()[idx])

    fn write_to[W: Writer](self, mut writer: W):
        self.func.write_call(self, writer)


@value
struct ExprMem[config: SymConfig]:
    var func_type: Int
    var func_idx: Int
    var out_idx: Int


@value
@register_passable
struct Expr[config: SymConfig, FuncT: Callable]:
    var graph: GraphRef[config]
    var idx: Int

    fn __repr__(self) -> String:
        return "hello"

    @implicit
    fn __init__[
        FT: Callable
    ](out self: Expr[config, AnyFunc], other: Expr[config, FT]):
        constrained[config.callables.supports[FT](), "Type not supported"]()
        self.graph = other.graph
        self.idx = other.idx

    fn __getitem__(self) -> ExprMem[config]:
        return self.graph[].exprs[self.idx]

    fn __getattr__[
        name: StringLiteral["call".value]
    ](self) -> Call[config, FuncT]:
        return Call[config, FuncT](self.graph, self[].func_idx)

    fn __getattr__[
        name: StringLiteral["args".value]
    ](self) -> ref [
        self.graph[].calls.ptr(self[].func_type, self[].func_idx)[].args
    ] StackList[Int]:
        return self.call.args

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
            config.callables.func_to_idx[FT]() == self[].func_type,
            "Function type mismatch",
        )
        return Expr[config, FT](self.graph, self.idx)

    # @staticmethod
    # fn is_known() -> Bool:
    #     return not _type_is_eq[FuncT, AnyFunc]()


#     var graph: GraphRef[config]
#     var idx: ArgIdx

#     fn __init__(out self, call: Call[config], idx: Int):
#         self.graph = call.graph
#         self.idx = ArgIdx(call.idx, idx)

# fn call(self) -> Call[config]:
#     return Call[config](self.graph, self.idx.call)

#     fn args(self, idx: Int) -> Expr[config]:
#         return Expr(self.graph, self.graph[].calls[self.idx.call].args[idx])


#     fn __add__(self, other: Self) -> Self:
#         return self.graph.add_call(Add(), self, other).outs(0)
