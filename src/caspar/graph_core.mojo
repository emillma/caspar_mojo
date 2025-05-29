from .val import Call
from memory import UnsafePointer
from .sysconfig import SymConfig
from .funcs import Callable, AnyFunc
from sys.intrinsics import sizeof, _type_is_eq
from collections import Set
from .collections import (
    FuncTypeIdx,
    CallInstanceIdx,
    CallIdx,
    ValIdx,
    OutIdx,
    IndexList,
)
from collections import BitSet
from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher
from caspar.utils import hash

alias BytePtr = UnsafePointer[Byte]


struct ValMem[config: SymConfig](Movable, _HashableWithHasher):
    var call_idx: CallIdx
    var out_idx: OutIdx
    var uses: Set[CallIdx]

    fn __init__(out self, call_idx: CallIdx, out_idx: OutIdx):
        self.call_idx = call_idx
        self.out_idx = out_idx
        self.uses = Set[CallIdx]()

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(self.call_idx)
        hasher.update(self.out_idx)


@value
struct CallFlags:
    var data: UInt8

    fn __init__(out self):
        self.data = 0

    fn used(self) -> Bool:
        return self.get_flag[0]()

    fn used(mut self, value: Bool):
        return self.set_flag[0](True)

    fn get_flag[idx: UInt](self) -> Bool:
        return self.data & (1 << idx) != 0

    fn set_flag[idx: UInt](mut self, value: Bool):
        if value:
            self.data |= 1 << idx
        else:
            self.data &= ~(1 << idx)


struct CallMem[FuncT: Callable, config: SymConfig](Movable, _HashableWithHasher):
    var args: IndexList[ValIdx]
    var outs: IndexList[ValIdx]
    var hash: UInt64
    var flags: CallFlags
    var func: FuncT  # Important to keep this field last for AnyFunc compatibility

    fn __init__(
        out self,
        owned args: IndexList[ValIdx],
        owned outs: IndexList[ValIdx],
        owned func: FuncT,
    ):
        self.args = args^
        self.outs = outs^
        self.func = func^
        self.flags = CallFlags()
        self.hash = hash(self.func, self.args)

    fn copy(self, out ret: Self):
        ret.args = self.args.copy()
        ret.outs = self.outs.copy()
        ret.func = self.func
        ret.hash = self.hash
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(ret))

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(self.func)
        hasher.update(self.args)

    fn same_call(self, other: Self) -> Bool:
        constrained[config.funcs.supports[FuncT](), "Type not supported"]()
        constrained[config == other.config, "Configurations do not match"]()
        constrained[_type_is_eq[FuncT, other.FuncT](), "Function types do not match"]()
        return (
            self.hash == other.hash
            and self.func == other.func
            and self.args == other.args
        )


struct GraphCore[config: SymConfig]:
    var call_ptrs: InlineArray[BytePtr, config.n_funcs, run_destructors=True]
    var call_counts: InlineArray[Int, config.n_funcs, run_destructors=True]
    var call_capacities: InlineArray[Int, config.n_funcs, run_destructors=True]
    var call_strides: InlineArray[Int, config.n_funcs, run_destructors=True]

    var val_ptr: UnsafePointer[ValMem[config]]
    var val_count: Int
    var val_capacity: Int

    fn __init__(out self):
        self.call_ptrs = __type_of(self.call_ptrs)(uninitialized=True)
        self.call_counts = __type_of(self.call_counts)(uninitialized=True)
        self.call_capacities = __type_of(self.call_capacities)(uninitialized=True)
        self.call_strides = __type_of(self.call_strides)(uninitialized=True)
        alias init_size = 500

        @parameter
        for i in config.funcs.range():
            alias CallT = CallMem[config.funcs.Ts[i], config]
            self.call_ptrs[i] = UnsafePointer[CallT].alloc(init_size).bitcast[Byte]()
            self.call_counts.unsafe_ptr().offset(i).init_pointee_move(0)
            self.call_capacities.unsafe_ptr().offset(i).init_pointee_move(init_size)
            self.call_strides.unsafe_ptr().offset(i).init_pointee_move(sizeof[CallT]())

        self.val_ptr = UnsafePointer[ValMem[config]].alloc(init_size)
        self.val_count = 0
        self.val_capacity = init_size

    fn __del__(owned self):
        @parameter
        for ft in config.funcs.range():
            alias CallT = CallMem[config.funcs.Ts[ft], config]
            for c in range(self.call_counts[ft]):
                self.call_ptrs[ft].bitcast[CallT]().offset(c).destroy_pointee()
            self.call_ptrs[ft].free()

        for v in range(self.val_count):
            self.val_ptr.offset(v).destroy_pointee()
        self.val_ptr.free()

    fn valmem[
        origin: Origin
    ](ref [origin]self, idx: ValIdx) -> ref [self.val_ptr] ValMem[config]:
        return self.val_ptr.offset(idx)[]

    fn valmem_add(mut self, call_idx: CallIdx, out_idx: OutIdx, out ret: ValIdx):
        UnsafePointer(to=self.valmem(self.val_count)).init_pointee_move(
            ValMem[config](call_idx=call_idx, out_idx=out_idx)
        )
        ret = self.val_count
        self.val_count += 1
        debug_assert(
            self.val_count <= self.val_capacity,
            "CallStorage is full for function type",
        )

    fn callmem_any[
        origin: Origin, //, FT: Callable
    ](ref [origin]self, idx: CallIdx) -> ref [self.call_ptrs[idx.type]] CallMem[
        FT, config
    ]:
        return (
            self.call_ptrs[idx.type]
            .offset(Int(idx.instance) * self.call_strides[idx.type])
            .bitcast[CallMem[FT, config]]()[]
        )

    fn callmem[
        mut: Bool, //, FT: Callable, origin: Origin[mut]
    ](ref [origin]self, idx: CallInstanceIdx) -> ref [
        self.call_ptrs[Self.ftype_idx[FT]()]
    ] CallMem[FT, config]:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.call_ptrs[ftype_idx].bitcast[CallMem[FT, config]]().offset(idx)[]

    fn callmem_add[
        FT: Callable
    ](mut self, owned func: FT, owned args: IndexList[ValIdx], out ret: CallIdx):
        alias ftype_idx = Self.ftype_idx[FT]()
        ret = CallIdx(ftype_idx, self.call_counts[ftype_idx])
        var outs = IndexList[ValIdx](capacity=FT.info.n_outs)
        for i in range(FT.info.n_outs):
            outs.append(self.valmem_add(ret, i))

        UnsafePointer(
            to=self.callmem[FT=FT](self.call_counts[ftype_idx])
        ).init_pointee_move(
            CallMem[FT, config](args=args^, outs=outs^, func=func),
        )
        self.call_counts[ftype_idx] += 1
        debug_assert(
            self.call_counts[ftype_idx] <= self.call_capacities[ftype_idx],
            "CallStorage is full for function type",
        )

    @staticmethod
    fn ftype_idx[FT: Callable]() -> Int:
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        return config.funcs.func_to_idx[FT]()
