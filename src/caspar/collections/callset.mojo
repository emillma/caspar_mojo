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
    var size: Int
    var capacity: Int
    var index: _DictIndex
    var entries: UnsafePointer[CallMem[config]]
    var stride: Int

    fn __init__(out self):
        constrained[sizeof[Self]() == sizeof[CallSet[config]]()]()
        alias INITIAL_CAPACITY = 200

        self.entries = UnsafePointer[Self.CallT].alloc(INITIAL_CAPACITY)
        self.capacity = INITIAL_CAPACITY
        self.size = 0
        self.index = _DictIndex(INITIAL_CAPACITY)
        self.stride = sizeof[Self.CallT]()

    @implicit
    fn __init__(out self: CallSet[config], owned other: CallSet[config]):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        UnsafePointer(to=self).bitcast[__type_of(other)]().init_pointee_move(other^)

    fn __getitem__(ref self, idx: CallIdx) -> ref [self.entries] Self.CallT:
        debug_assert(-self.size <= Int(idx) < self.size, "Index out of bounds")
        if idx >= 0:
            return self.entries.offset(idx)[]
        else:
            return self.entries.offset(idx + self.size)[]

    fn search(self, call: Self.CallT) -> SearchResult:
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

    fn insert[
        unsafe: Bool = False
    ](mut self, owned call: Self.CallT, idx: SearchResult):
        debug_assert(not idx.found)

        @parameter
        if not unsafe:
            self._maybe_resize()
        self.entries.offset(idx.index).init_pointee_move(call^)
        self.index.set_index(Int(self.capacity), Int(idx.slot), Int(idx.index))
        self.size += 1

    fn _maybe_resize(self):
        if 3 * self.size >= 2 * self.capacity:
            debug_assert(False, "Resizing not implemented")

    fn __len__(self) -> Int:
        return self.size
