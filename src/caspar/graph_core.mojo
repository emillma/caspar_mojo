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
    ArgIdx,
    IndexList,
)
from collections import BitSet
from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher
from caspar.utils import hash
from caspar.collections import CallSet

alias BytePtr = UnsafePointer[Byte]


struct ValMem[config: SymConfig](Movable,Copyable):
    var call_idx: CallIdx
    var out_idx: OutIdx
    var uses: Dict[CallIdx, IndexList[ArgIdx]]

    fn __init__(out self, call_idx: CallIdx, out_idx: OutIdx):
        self.call_idx = call_idx
        self.out_idx = out_idx
        self.uses = Dict[CallIdx, IndexList[ArgIdx]]()


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


struct CallMem[FuncT: Callable, config: SymConfig](Movable,ExplicitlyCopyable, _HashableWithHasher):
    var args: IndexList[ValIdx]
    var outs: IndexList[ValIdx]
    var hash: UInt64
    var flags: CallFlags
    var func: FuncT  # Important to keep this field last for AnyFunc compatibility

    fn __init__(
        out self,
        owned func: FuncT,
        owned args: IndexList[ValIdx]
    ):
        constrained[config.funcs.supports[FuncT](), "Type not supported"]()
        debug_assert(len(args) == FuncT.info.n_args or FuncT.info.n_args == -1)
        self.func = func^
        self.args = args^
        self.outs = IndexList[ValIdx](capacity=FuncT.info.n_outs)
        
        self.flags = CallFlags()
        self.hash = hash(self.func, self.args)

    fn copy(self, out ret: Self):
        constrained[config.funcs.supports[FuncT](), "Type not supported"]()
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
    """The symbolic graph core that holds the call sets and value memory."""
    var callsets: __mlir_type[
        `!pop.array<`, len(config.funcs).value, `, `, CallSet[AnyFunc, config], `>`
    ]

    var vals: List[ValMem[config]]


    fn __init__(out self):
        self.vals = List[ValMem[config]]()

        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self.callsets))
        @parameter
        for i in config.funcs.range():
            self.callset_ptr[FT=config.funcs.Ts[i]]().init_pointee_move(
                CallSet[config.funcs.Ts[i], config]())
                
    fn callset_ptr[
        FT: Callable, origin:Origin
    ](ref [origin]self, ftype_idx: FuncTypeIdx = -1
    ) -> UnsafePointer[type=CallSet[FT, config],
        mut = origin.mut,
        origin = origin
    ]:
        var idx: FuncTypeIdx
        @parameter
        if _type_is_eq[FT, AnyFunc]():
            debug_assert(0 <= Int(ftype_idx) < len(config.funcs))
            idx = ftype_idx
        else:
            debug_assert(ftype_idx == -1 or ftype_idx == Self.ftype_idx[FT]())
            idx= Self.ftype_idx[FT]()

        return  UnsafePointer(to=self.callsets)
            .bitcast[CallSet[FT, config]]()
            .offset(idx)
            .origin_cast[
                mut = origin.mut,
                origin = origin
            ]()

    fn callset[
        FT: Callable, origin: Origin
    ](ref [origin]self, ftype_idx: FuncTypeIdx = -1) -> ref [
        self.callset_ptr[FT=FT](ftype_idx)[]] CallSet[FT, config]:
        return self.callset_ptr[FT=FT](ftype_idx)[]

    fn valmem_get[
        origin: Origin
    ](ref [origin]self, idx: ValIdx) -> ref [self.vals[idx]] ValMem[config]:
        return self.vals[idx]

    fn valmem_add(mut self, call_idx: CallIdx, out_idx: OutIdx, out ret: ValIdx):        
        ret = len(self.vals)
        self.vals.append(ValMem[config](call_idx=call_idx, out_idx=out_idx))

    fn callmem_get[
         FT: Callable
    ](ref self, idx: CallIdx) -> ref [
        self.callset_ptr[FT=FT](idx.type)[][idx.instance]] CallMem[
        FT, config
    ]:
        return self.callset_ptr[FT=FT](idx.type)[][idx.instance]

    fn callmem_add[
        FT: Callable
    ](mut self, owned func: FT, owned args: IndexList[ValIdx], out ret: CallIdx):

        alias ftype_idx = Self.ftype_idx[FT]()
        
        var call = CallMem[FT, config](func, args^)
        var idx = self.callset[FT=FT](ftype_idx).search(call)
        ret = CallIdx(ftype_idx, idx.index)
        for i in range(len(call.args)):
            try:
                self.valmem_get(call.args[i]
                ).uses.setdefault(ret, IndexList[ArgIdx]()
                ).append(i)
            except KeyError:
                debug_assert(False)

        if not idx.found:
            for i in range(FT.info.n_outs):
                call.outs.append(self.valmem_add(ret, i))
            self.callset[FT=FT](ftype_idx).insert(call^, idx)
        
    @staticmethod
    fn ftype_idx[FT: Callable]() -> Int:
        constrained[config.funcs.supports[FT](), "Type not supported"]()
        return config.funcs.func_to_idx[FT]()
