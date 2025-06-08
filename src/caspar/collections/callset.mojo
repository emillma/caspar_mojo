import math
from sys.info import sizeof

from caspar.sysconfig import SymConfig
from caspar.funcs import Callable, AnyFunc
from caspar.graph import CallMem, ValMem

from collections.dict import _EMPTY, _REMOVED, _DictIndex
from memory import UnsafePointer, memcpy
from . import CallIdx, ValIdx, OutIdx, IndexList, CallIdx
from .bitlist import BitList


@value
@register_passable("trivial")
struct SearchResult:
    var found: Bool
    var slot: UInt64
    var index: Int


struct CallSet[config: SymConfig](Movable, Sized):
    alias CallT = CallMem[config]
    var count: Int
    var capacity: Int
    var index: _DictIndex
    var entries: UnsafePointer[CallMem[config]]
    var stride: Int

    fn __init__(out self, capacity: Int = 128):
        constrained[sizeof[Self]() == sizeof[CallSet[config]]()]()
        debug_assert(capacity.is_power_of_two())

        self.entries = UnsafePointer[Self.CallT].alloc(capacity)
        self.capacity = capacity
        self.count = 0
        self.index = _DictIndex(capacity)
        self.stride = sizeof[Self.CallT]()

    @implicit
    fn __init__(out self: CallSet[config], owned other: CallSet[config]):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        UnsafePointer(to=self).bitcast[__type_of(other)]().init_pointee_move(other^)

    fn __getitem__(ref self, idx: CallIdx) -> ref [self.entries] Self.CallT:
        debug_assert(-self.count <= Int(idx) < self.count, "Index out of bounds")
        if idx >= 0:
            return self.entries.offset(idx)[]
        else:
            return self.entries.offset(idx + self.count)[]

    fn search(self, call: Self.CallT) -> SearchResult:
        var slot = call.hash & (self.capacity - 1)
        var perturb = call.hash
        while True:
            var index = self.index.get_index(self.capacity, slot)
            if index == _EMPTY:
                return SearchResult(False, slot, self.count)
            if index == _REMOVED:
                pass
            else:
                var entry = Pointer(to=self.entries[index])
                if call.same_call(self.entries[index]):
                    return SearchResult(True, slot, index)
            self._next_index_slot(slot, perturb)

    fn _next_index_slot(self, mut slot: UInt, mut perturb: UInt):
        alias PERTURB_SHIFT = 5
        perturb >>= PERTURB_SHIFT
        slot = ((5 * slot) + Int(perturb + 1)) & (self.capacity - 1)

    fn insert[
        unsafe: Bool = False
    ](mut self, owned call: Self.CallT, idx: SearchResult):
        debug_assert(not idx.found)

        @parameter
        if not unsafe:
            self._maybe_resize()
        self.entries.offset(idx.index).init_pointee_move(call^)
        self.index.set_index(Int(self.capacity), Int(idx.slot), Int(idx.index))
        self.count += 1

    fn _maybe_resize(self):
        if 3 * self.count >= 2 * self.capacity:
            debug_assert(False, "Resizing not implemented")

    fn __len__(self) -> Int:
        return self.count
