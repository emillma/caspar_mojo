from memory import Pointer, Span, UnsafePointer, memcpy


struct OwnedList[T: CollectionElementNew, static_allocation: Int = 1]:
    # constrained[True, "Must allocate at least one element"]()
    var static_memory: __mlir_type[`!pop.array<`, static_allocation.value, `, `, T, `>`]
    var data: UnsafePointer[T]
    var _len: Int
    var _capacity: Int

    fn __init__(out self, capacity: Int = static_allocation):
        constrained[static_allocation > 0, "Must allocate at least one element"]()
        self._len = 0
        self._capacity = capacity
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self.data = UnsafePointer(to=self.static_memory).bitcast[T]()
        self.reserve(max(1, capacity))

    fn __moveinit__(out self, owned other: OwnedList[T]):
        self._len = other._len
        self._capacity = other._capacity
        self.data = other.data
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))

    fn copy(self) -> Self:
        var out = Self(capacity=self._capacity)
        for i in range(self._len):
            out.append(self.data[i].copy())
        return out^

    fn __getitem__(ref self, idx: Int) -> ref [self] T:
        debug_assert(-len(self) <= idx < len(self), "index out of range")
        return self.data[idx if idx >= 0 else len(self) + idx]

    fn append(mut self, owned item: T):
        if self._len == self._capacity:
            self._realloc(self._capacity * 2)
        self._unsafe_next_uninit_ptr().init_pointee_move(item^)
        self._len += 1

    fn reserve(mut self, capacity: Int):
        if capacity > self._capacity:
            self._realloc(capacity)

    fn _realloc(mut self, new_capacity: Int):
        var new_data = UnsafePointer[T].alloc(new_capacity)
        for i in range(len(self)):
            (self.data + i).move_pointee_into(new_data + i)
        self.data = new_data

    @always_inline
    fn _unsafe_next_uninit_ptr(
        ref self,
    ) -> UnsafePointer[
        T, mut = Origin(__origin_of(self)).is_mutable, origin = __origin_of(self)
    ]:
        debug_assert(self._capacity > 0 and self._capacity > self._len)
        return self.data + self._len

    fn __len__(self) -> Int:
        return self._len
