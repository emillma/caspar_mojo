from .sysconfig import SymConfig
from memory import UnsafePointer
from . import funcs
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat
from .expr import Call, Expr, CasparElement
from .graph_utils import CallIdx, ExprIdx, OutIdx, StackList, CallInstanceIdx
from sys.intrinsics import _type_is_eq
from sys import sizeof, alignof


struct CallTable[config: SymConfig]:
    var ptrs: InlineArray[UnsafePointer[Byte], config.n_funcs, run_destructors=True]
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
            alias CallT = CallMem[config.funcs.Ts[i], config]
            self.ptrs[i] = UnsafePointer[CallT].alloc(init_size).bitcast[Byte]()
            self.counts.unsafe_ptr().offset(i).init_pointee_move(0)
            self.capacities.unsafe_ptr().offset(i).init_pointee_move(init_size)
            self.strides.unsafe_ptr().offset(i).init_pointee_move(sizeof[CallT]())

    fn __del__(owned self):
        @parameter
        for i in config.funcs.range():
            alias CallT = CallMem[config.funcs.Ts[i], config]
            for j in range(self.counts[i]):
                self.ptrs[i].bitcast[CallT]().destroy_pointee()
            self.ptrs[i].free()

    fn ptr[
        FT: Callable
    ](mut self, idx: CallInstanceIdx) -> UnsafePointer[
        CallMem[FT, config], origin = __origin_of(self.ptrs)
    ]:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.ptrs[ftype_idx].bitcast[CallMem[FT, config]]().offset(idx)

    fn ptr(
        mut self, idx: CallIdx
    ) -> UnsafePointer[CallMem[AnyFunc, config], origin = __origin_of(self.ptrs)]:
        return (
            self.ptrs[idx.type]
            .offset(Int(idx.instance) * self.strides[idx.type])
            .bitcast[CallMem[AnyFunc, config]]()
        )

    fn add[FT: Callable](mut self, owned call_mem: CallMem[FT, config]):
        alias ftype_idx = Self.ftype_idx[FT]()
        debug_assert(
            self.counts[ftype_idx] < self.capacities[ftype_idx],
            "CallStorage is full for function type",
        )
        self.ptr[FT](self.counts[ftype_idx]).init_pointee_move(call_mem^)
        self.counts[ftype_idx] += 1

    @staticmethod
    fn call_idx[FT: Callable](idx: CallInstanceIdx) -> CallIdx:
        return CallIdx(Self.ftype_idx[FT](), idx)

    @staticmethod
    fn ftype_idx[FT: Callable]() -> Int:
        return config.funcs.func_to_idx[FT]()

    fn count[FT: Callable](self) -> Int:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.counts[ftype_idx]

    fn capacity[FT: Callable](self) -> Int:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.capacities[ftype_idx]


struct GraphMem[config: SymConfig]:
    var calls: CallTable[config]
    var exprs: List[ExprMem[config]]
    var refcount: Int

    fn __init__(out self):
        self.calls = CallTable[config]()
        self.exprs = List[ExprMem[config]]()
        self.refcount = 1

    fn add_ref(mut self):
        self.refcount += 1

    fn drop_ref(mut self) -> Bool:
        self.refcount -= 1
        debug_assert(self.refcount >= 0, "Refcount should never be negative")
        return self.refcount == 0


@value
struct ExprMem[config: SymConfig]:
    var call_idx: CallIdx
    var out_idx: OutIdx


@value
struct CallMem[FuncT: Callable, config: SymConfig]:
    var args: StackList[ExprIdx]
    var outs: StackList[ExprIdx]
    var func: FuncT


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

    fn __is__(self, other: GraphRef) -> Bool:
        @parameter
        if not self.config == other.config:
            return False
        else:
            return self.ptr == rebind[__type_of(self.ptr)](other.ptr)

    fn add_call[
        FT: Callable,
        *ArgTs: CasparElement,
    ](self, owned func: FT, owned *args: *ArgTs) -> Call[FT, config]:
        var arglist = StackList[ExprIdx](capacity=len(args))

        @parameter
        fn inner[idx: Int, T: CasparElement](arg: T):
            arglist.append(arg.as_expr(self).idx)

        args.each_idx[inner]()

        var outlist = StackList[ExprIdx](capacity=func.n_outs())
        var call_idx = self[].calls.call_idx[FT](self[].calls.count[FT]())
        for i in range(func.n_outs()):
            outlist.append(len(self[].exprs))
            self[].exprs.append(ExprMem[config](call_idx, i))

        self[].calls.add[FT](CallMem[FT, config](arglist, outlist, func))
        return Call[FT, config](self, call_idx)

    fn add_float(self, value: Floatable) -> Expr[AnyFunc, config]:
        var fval = value.__float__()
        if fval == 0:
            return self.add_call(funcs.StoreZero())[0]
        elif fval == 1:
            return self.add_call(funcs.StoreOne())[0]
        else:
            return self.add_call(funcs.StoreFloat(fval))[0]

    fn as_function(owned self, owned *args: Call[AnyFunc, config]) -> SymFunc[config]:
        arglist = List[CallIdx](capacity=len(args))
        for arg in args:
            arglist.append(arg[].idx)
        return SymFunc[config](self, arglist)


@value
struct SymFunc[config: SymConfig]:
    var graph: GraphRef[config]
    var args: List[CallIdx]
