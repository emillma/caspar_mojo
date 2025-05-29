import math
from memory import memcpy, UnsafePointer, memset


@value
struct BitList:
    var data: UnsafePointer[UInt64]
    var capacity: Int

    fn __init__(out self, bit_capacity: Int = 64):
        debug_assert(bit_capacity > 0, "Capacity must be greater than 0")
        self.capacity = math.align_up(bit_capacity, 64) // 64
        self.data = UnsafePointer[UInt64].alloc(self.capacity)
        memset(self.data, 0, self.capacity)

    fn get(self, bit: Int) -> Bool:
        debug_assert(bit >= 0, "Bit index must be non-negative")
        debug_assert(bit < self.capacity * 64, "Bit index out of bounds")
        var ret = divmod(bit, 64)
        return (self.data[ret[0]] & (1 << ret[1])) != 0

    fn set(mut self, bit: Int, value: Bool):
        debug_assert(bit >= 0, "Bit index must be non-negative")
        debug_assert(bit < self.capacity * 64, "Bit index out of bounds")
        var ret = divmod(bit, 64)
        if value:
            self.data[ret[0]] |= 1 << ret[1]
        else:
            self.data[ret[0]] &= ~(1 << ret[1])

    fn _realloc(mut self, new_bit_capacity: Int):
        debug_assert(new_bit_capacity >= self.capacity * 64)
        var new_capacity = math.align_up(new_bit_capacity, 64) // 64
        if new_capacity == self.capacity:
            return  # No need to reallocate if the capacity is the same
        new_data = UnsafePointer[UInt64].alloc(new_capacity)
        memcpy(new_data, self.data, self.capacity)
        memset(new_data + self.capacity, 0, new_capacity - self.capacity)
        self.data.free()
        self.data = new_data
        self.capacity = new_capacity
