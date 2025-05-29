import math
from sys.info import sizeof

from caspar.sysconfig import SymConfig
from caspar.funcs import Callable, AnyFunc
from caspar.graph import CallMem, ValMem

from collections.dict import _EMPTY, _REMOVED, _DictIndex
from memory import UnsafePointer, memcpy
from . import CallIdx, ValIdx, OutIdx, IndexList, CallInstanceIdx
from .bitlist import BitList


@value
@register_passable("trivial")
struct SearchResult:
    var found: Bool
    var slot: UInt64
    var index: Int


struct CallSet[FuncT: Callable, config: SymConfig](Movable):
    alias CallT = CallMem[FuncT, config]

    var size: Int
    var capacity: Int
    var index: _DictIndex
    var entries: UnsafePointer[Self.CallT]
    var stride: Int

    fn __init__(out self):
        constrained[sizeof[Self]() == sizeof[CallSet[AnyFunc, config]]()]()
        alias INITIAL_CAPACITY = 16

        self.entries = UnsafePointer[Self.CallT].alloc(INITIAL_CAPACITY)
        self.capacity = INITIAL_CAPACITY
        self.size = 0
        self.index = _DictIndex(INITIAL_CAPACITY)
        self.stride = sizeof[Self.CallT]()

    @implicit
    fn __init__(out self: CallSet[AnyFunc, config], owned other: CallSet[_, config]):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        UnsafePointer(to=self).bitcast[__type_of(other)]().init_pointee_move(other^)

    fn _find_index(self, call: Self.CallT) -> SearchResult:
        # Return (found, slot, index)
        var slot = call.hash & (self.capacity - 1)
        var perturb = call.hash
        while True:
            var index = self.index.get_index(self.capacity, slot)
            if index == _EMPTY:
                return SearchResult(False, slot, self.size)
            if index == _REMOVED:
                pass
            else:
                var entry = Pointer(to=self.entries[index])
                if call.same_call(self.entries[index]):
                    return SearchResult(True, slot, index)
            self._next_index_slot(slot, perturb)

    fn _next_index_slot(self, mut slot: UInt64, mut perturb: UInt64):
        alias PERTURB_SHIFT = 5
        perturb >>= PERTURB_SHIFT
        slot = ((5 * slot) + Int(perturb + 1)) & (self.capacity - 1)

    fn add[unsafe: Bool = False](mut self, owned call: Self.CallT):
        if (ret := self._find_index(call)).found:
            pass
        else:

            @parameter
            if not unsafe:
                self._maybe_resize()
            self.entries.offset(ret.index).init_pointee_move(call^)
            self.index.set_index(Int(self.capacity), Int(ret.slot), Int(ret.index))
            self.size += 1

    fn _maybe_resize(self):
        if 3 * self.size >= 2 * self.capacity:
            debug_assert(False, "Resizing not implemented")

    fn __len__(self) -> Int:
        return self.size


fn get_offsets[config: SymConfig, *Ts: Callable](out ret: List[Int]):
    ret = List[Int](capacity=len(VariadicList(Ts)) + 1)
    ret.append(0)

    @parameter
    for i in range(len(VariadicList(Ts))):
        ret.append(sizeof[CallMem[Ts[i], config]]())


struct MultiDict[config: SymConfig]:
    """A multi-dictionary that can hold multiple values for each key."""

    alias offsets = get_offsets[config, *config.funcs.Ts]()
