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
    var order: List[CallIdx]

    fn __init__(out self):
        self.ptrs = __type_of(self.ptrs)(uninitialized=True)
        self.counts = __type_of(self.counts)(uninitialized=True)
        self.capacities = __type_of(self.capacities)(uninitialized=True)
        self.strides = __type_of(self.strides)(uninitialized=True)
        self.order = List[CallIdx]()
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
        FT: Callable,
        mut: Bool,
        origin: Origin[mut],
    ](ref [origin]self, idx: CallIdx) -> UnsafePointer[
        CallMem[FT, config], mut=mut, origin=origin
    ]:
        @parameter
        if _type_is_eq[FT, AnyFunc]():
            return rebind[UnsafePointer[CallMem[FT, config]]](
                self.ptrs[idx.type]
                .offset(Int(idx.instance) * self.strides[idx.type])
                .bitcast[CallMem[AnyFunc, config]]()
            )
        else:
            alias ftype_idx = Self.ftype_idx[FT]()
            return (
                self.ptrs[ftype_idx].bitcast[CallMem[FT, config]]().offset(idx.instance)
            )

    fn get[
        FT: Callable
    ](self, idx: CallIdx) -> ref [self.ptr[FT](idx)[]] CallMem[FT, config]:
        return self.ptr[FT](idx)[]

    fn add_call[FT: Callable](mut self, owned call_mem: CallMem[FT, config]):
        alias ftype_idx = Self.ftype_idx[FT]()
        debug_assert(
            self.counts[ftype_idx] < self.capacities[ftype_idx],
            "CallStorage is full for function type",
        )
        self.ptr[FT](CallIdx(-1, self.counts[ftype_idx])).init_pointee_move(call_mem^)
        self.order.append(CallIdx(ftype_idx, self.counts[ftype_idx]))
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


struct MutLock:
    fn __init__(out self):
        ...

    fn __moveinit__(out self, owned other: Self):
        ...

    fn __enter__(mut self) -> Int:
        return 2

    fn __exit__(mut self):
        return


struct Graph[config: SymConfig]:
    alias LockToken = Int
    var calls: CallTable[config]
    var exprs: List[ExprMem[config]]
    var refcount: Int

    fn __init__(out self):
        self.calls = CallTable[config]()
        self.exprs = List[ExprMem[config]]()
        self.refcount = 1

    fn mut(
        self, token: Self.LockToken
    ) -> ref [MutableOrigin.cast_from[__origin_of(self)].result] Self:
        # TODO: add lock to ensure single mutability
        return UnsafePointer(to=self).origin_cast[
            True, MutableOrigin.cast_from[__origin_of(self)].result
        ]()[]

    fn get_call[
        FT: Callable = AnyFunc
    ](self, idx: CallIdx) -> Call[AnyFunc, config, __origin_of(self)]:
        debug_assert(
            config.funcs.func_to_idx[FT]() == Int(idx.type), "Type mismatch in get_call"
        )
        return Call[FT](Pointer(to=self), idx)

    fn get_expr[
        FT: Callable = AnyFunc
    ](self, idx: ExprIdx) -> Expr[FT, config, __origin_of(self)]:
        debug_assert(
            config.funcs.func_to_idx[FT]() == Int(self.exprs[idx].call_idx.type),
            "Type mismatch in get_expr",
        )
        return Expr[FT](Pointer(to=self), idx)

    fn add_call[
        FT: Callable,
        *ArgTs: CasparElement,
    ](self, owned func: FT, owned *args: *ArgTs) -> Call[FT, config, __origin_of(self)]:
        var arglist = StackList[ExprIdx](capacity=len(args))

        @parameter
        fn inner[idx: Int, T: CasparElement](arg: T):
            arglist.append(arg.as_expr(self).idx)

        args.each_idx[inner]()
        var outlist = StackList[ExprIdx](capacity=func.n_outs())
        var call_idx = self.calls.call_idx[FT](self.calls.count[FT]())
        with MutLock() as token:
            for i in range(func.n_outs()):
                outlist.append(len(self.exprs))
                self.mut(token).exprs.append(ExprMem[config](call_idx, i))
            self.mut(token).calls.add_call[FT](
                CallMem[FT, config](arglist, outlist, func)
            )
        return Call[FT, config, __origin_of(self)](Pointer(to=self), call_idx)


@value
struct ExprMem[config: SymConfig]:
    var call_idx: CallIdx
    var out_idx: OutIdx


@value
struct CallMem[FuncT: Callable, config: SymConfig]:
    var args: StackList[ExprIdx]
    var outs: StackList[ExprIdx]
    var func: FuncT
