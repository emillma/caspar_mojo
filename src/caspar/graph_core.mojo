from .val import Call
from memory import UnsafePointer
from .funcs import Callable, AnyFunc
from sys.intrinsics import sizeof, _type_is_eq
from collections import Set
from .collections import (
    CallIdx,
    ValIdx,
    OutIdx,
    ArgIdx,
    IndexList,
)
from collections import BitSet
from caspar.utils import hash
from caspar.collections import CallSet
from caspar.collections.callset import SearchResult
from .utils import multihash, hashupdate
from caspar.config import FuncVariant

alias BytePtr = UnsafePointer[Byte]


struct ValMem(Movable, Copyable, Hashable):
    var call: CallIdx
    var out_idx: OutIdx
    var uses: Dict[CallIdx, IndexList[ArgIdx]]

    fn __init__(out self, call: CallIdx, out_idx: OutIdx):
        self.call = call
        self.out_idx = out_idx
        self.uses = Dict[CallIdx, IndexList[ArgIdx]]()

    fn __hash__(self) -> UInt:
        return multihash(self.call, self.out_idx)


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

    fn __eq__(self, other: Self) -> Bool:
        return self.data == other.data


struct CallMem(Movable, ExplicitlyCopyable, Hashable):
    var args: IndexList[ValIdx]
    var outs: IndexList[ValIdx]
    var hash: UInt
    var flags: CallFlags
    var func: FuncVariant

    fn __init__(out self, owned func: FuncVariant, owned args: IndexList[ValIdx]):
        self.func = func^
        self.args = args^
        self.hash = 0
        self.outs = IndexList[ValIdx](capacity=self.func.info().n_outs)
        self.flags = CallFlags()

    fn __init__[FT: Callable](out self, owned func: FT, owned args: IndexList[ValIdx]):
        debug_assert(len(args) == FT.info.n_args or FT.info.n_args == -1)
        self.func = func^
        self.args = args^
        self.hash = 0
        self.outs = IndexList[ValIdx](capacity=FT.info.n_outs)
        self.flags = CallFlags()

    fn copy(self, out ret: Self):
        ret.args = self.args.copy()
        ret.outs = self.outs.copy()
        ret.func = self.func
        ret.hash = self.hash
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(ret))

    fn __hash__(self) -> UInt:
        return self.hash

    fn same_call(self, other: Self) -> Bool:
        return self.func == other.func and self.args == other.args


struct GraphCore(Movable):
    """The symbolic graph core that holds the call sets and value memory."""

    var calls: CallSet

    var vals: List[ValMem]

    fn __init__(out self, capacity: Int = 128):
        self.vals = List[ValMem](capacity=capacity)
        self.calls = CallSet(capacity=capacity)

    fn valmem_add(mut self, call: CallIdx, out_idx: OutIdx, out ret: ValIdx):
        ret = len(self.vals)
        self.vals.append(ValMem(call=call, out_idx=out_idx))

    fn __getitem__(ref self, idx: CallIdx) -> ref [self.calls[idx]] CallMem:
        return self.calls[idx]

    fn __getitem__(ref self, idx: ValIdx) -> ref [self.vals[idx]] ValMem:
        return self.vals[idx]

    fn callmem_add(
        mut self,
        owned func: FuncVariant,
        owned args: IndexList[ValIdx],
        out ret: CallIdx,
    ):
        var call = CallMem(func, args^)
        var idx = self.calls.search(call)
        ret = idx.index

        for i in range(len(call.args)):
            try:
                self[call.args[i]].uses.setdefault(ret, IndexList[ArgIdx]()).append(i)
            except KeyError:
                debug_assert(False)
        if not idx.found:
            for i in range(func.info().n_outs):
                call.outs.append(self.valmem_add(ret, i))

            call.hash = hash(call.func)
            for arg in call.args:
                hashupdate(call.hash, self[arg])
            self.calls.insert(call^, idx)
