from memory import UnsafePointer
from sys import sizeof
from .sysconfig import SymConfig
from .functions import Callable, AnyFunc
from .graph_utils import CallIdx, ExprIdx, OutIdx, FuncTypeIdx, StackList
from .expr import CallMem, ExprMem, Call, Expr


struct CallStorage[config: SymConfig]:
    var ptrs: InlineArray[
        UnsafePointer[Byte], config.n_funcs, run_destructors=True
    ]
    var counts: InlineArray[Int, config.n_funcs, run_destructors=True]
    var capacities: InlineArray[Int, config.n_funcs, run_destructors=True]
    var strides: InlineArray[Int, config.n_funcs, run_destructors=True]

    fn __init__(out self):
        self.ptrs = __type_of(self.ptrs)(uninitialized=True)
        self.counts = __type_of(self.counts)(uninitialized=True)
        self.capacities = __type_of(self.capacities)(uninitialized=True)
        self.strides = __type_of(self.strides)(uninitialized=True)
        alias init_size = 100

        @parameter
        for i in config.funcs.range():
            alias CallT = CallMem[config, config.funcs.Ts[i]]
            self.ptrs[i] = UnsafePointer[CallT].alloc(init_size).bitcast[Byte]()
            self.counts.unsafe_ptr().offset(i).init_pointee_move(0)
            self.capacities.unsafe_ptr().offset(i).init_pointee_move(init_size)
            self.strides.unsafe_ptr().offset(i).init_pointee_move(
                sizeof[CallT]()
            )

    fn __del__(owned self):
        @parameter
        for i in config.funcs.range():
            alias CallT = CallMem[config, config.funcs.Ts[i]]
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
        return config.funcs.func_to_idx[FT]()

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
                    config.funcs.func_to_idx[FT](),
                    self[].calls.count[FT](),
                    i,
                )
            )

        self[].calls.add[FT](CallMem[config, FT](arglist, outlist, func))

        return Call[config, FT](self, self[].calls.count[FT]() - 1)
