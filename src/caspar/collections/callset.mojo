import math
from sys.info import sizeof

from caspar.sysconfig import SymConfig
from caspar.funcs import Callable
from caspar.graph import CallMem, ValMem
from collections.dict import _EMPTY, _REMOVED, _DictIndex
from memory import UnsafePointer, memcpy
from . import CallIdx, ValIdx, OutIdx, IndexList, CallInstanceIdx

@value
struct Pair[K: ExplicitlyCopyable & Movable, V: ExplicitlyCopyable & Movable]:
    var key: K
    var value: V   


struct CallDict[FuncT: Callable, config: SymConfig]:
    alias EMPTY = _EMPTY
    alias REMOVED = _REMOVED
    alias K = CallMem[FuncT, config]
    alias V = IndexList[OutIdx]
    alias Item = Pair[Self.K, Self.V]

    var _len: Int
    var _n_entries: Int 
    var _capacity: Int
    var _index: _DictIndex
    var _entries: UnsafePointer[Self.Item]

    fn __init__(out self, capacity: Int = 8):
        debug_assert(capacity.is_power_of_two(), "Capacity must be a power of two")
        debug_assert(capacity >= 8, "Capacity must be at least 8")
        self._entries = UnsafePointer[Self.Item].alloc(capacity)
        self._capacity = capacity
        self._len = 0
        self._n_entries = 0
        self._index = _DictIndex(capacity)

    fn __getitem__(
        self, key: Self.K
    ) raises -> ref [self._entries] Self.V:
        return self._find_ref(key)

    fn __setitem__(mut self, owned key: Self.K, owned value: Self.V):
        self._insert(key^, value^)

    fn _find_ref(self, key: Self.K) raises -> ref [self._entries] Self.V:
        found, _, index = self._find_index(key)
        if found:
            return self._entries[index].value
        else:
            raise "KeyError"
    fn _find_index(self, key: Self.K) -> (Bool, UInt64, Int):
        # Return (found, slot, index)
        var slot = key.hash & (self._reserved() - 1)
        var perturb = key.hash
        while True:
            var index = self._get_index(slot)
            if index == Self.EMPTY:
                return (False, slot, self._len)
            elif index == Self.REMOVED:
                # Different from Dict, we do not keep order.
                return (False, slot, self._len)
                
            else:
                var entry = Pointer(to=self._entries[index])
                if key == entry[].key:
                    return (True, slot, index)
            self._next_index_slot(slot, perturb)

    fn _get_index(self, slot: UInt64) -> Int:
        return self._index.get_index(self._reserved(), slot)

    fn _next_index_slot(self, mut slot: UInt64, mut perturb: UInt64):
        alias PERTURB_SHIFT = 5
        perturb >>= PERTURB_SHIFT
        slot = ((5 * slot) + Int(perturb + 1)) & (self._reserved() - 1)

    fn _insert[
        safe_context: Bool = False
    ](mut self, owned key: Self.K, owned value: Self.V):
        @parameter
        if not safe_context:
            self._maybe_resize()
        var entry = Self.Item(key=key^, value=value^)
        var found: Bool
        var slot: UInt64
        var index: Int
        found, slot, index = self._find_index(entry.key)

        self._entries[index] = entry^
        if not found:
            self._set_index(slot, index)
            self._len += 1
            self._n_entries += 1

    fn _maybe_resize(self):
        if 3*self._len >= 2*self._reserved():
            debug_assert(False, "Resizing not implemented")
    fn _reserved(self) -> Int:
        return Int(self._reserved()) - 1
    fn _set_index(mut self, slot: UInt64, index: Int):
        
        return self._index.set_index(self._reserved(), slot, index)             

fn get_offsets[config: SymConfig, *Ts: Callable](out ret: List[Int]):
    ret = List[Int](capacity=len(VariadicList(Ts)) + 1)
    ret.append(0)

    @parameter
    for i in range(len(VariadicList(Ts))):
        ret.append(sizeof[CallMem[Ts[i], config]]())

struct MultiDict[config: SymConfig]:
    """A multi-dictionary that can hold multiple values for each key."""

    alias offsets = get_offsets[config, *config.funcs.Ts]()
    var 