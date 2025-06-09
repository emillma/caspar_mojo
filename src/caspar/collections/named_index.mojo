from memory import UnsafePointer, memcpy
from sys.intrinsics import sizeof
from ..utils import multihash


trait NamedIndexT(Movable, Copyable, Indexer, KeyElement, Writable):
    alias name_: StaticString


@fieldwise_init("implicit")
@register_passable("trivial")
struct NamedIndex[T: StringLiteral](NamedIndexT):
    alias name_ = StaticString(T)
    var value: Int

    fn __index__(self) -> __mlir_type.index:
        return self.value.__index__()

    fn __int__(self) -> Int:
        return self.value

    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __ne__(self, other: Self) -> Bool:
        return not self.value == other.value

    fn __req__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __hash__(self) -> UInt:
        return hash(self.value)

    fn __lt__(self, other: Self) -> Bool:
        return self.value < other.value

    fn __gt__(self, other: Self) -> Bool:
        return self.value > other.value

    fn __le__(self, other: Self) -> Bool:
        return self.value <= other.value

    fn __ge__(self, other: Self) -> Bool:
        return self.value >= other.value

    fn __add__(self, other: Self) -> Self:
        return Self(value=self.value + other.value)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(T, ": ", self.value)


alias IndexT = Movable & Copyable & KeyElement & Indexer
alias FuncTypeIdx = NamedIndex["FuncTypeIdx"]
alias CallIdx = NamedIndex["CallIdx"]

alias ValIdx = NamedIndex["ValIdx"]

alias ArgIdx = NamedIndex["ArgIdx"]
alias OutIdx = NamedIndex["OutIdx"]

alias RegIdx = NamedIndex["RegIdx"]


struct IndexList[ElemT: NamedIndexT, stack_size: Int = 4](
    Sized, Copyable, Movable, ExplicitlyCopyable, Hashable, Writable
):
    var capacity: UInt32
    var count: UInt32

    alias type = __mlir_type[`!pop.array<`, stack_size.value, `, `, ElemT, `>`]
    var stack_data: Self.type

    fn __init__(out self, owned capacity: UInt32 = stack_size):
        capacity = max(capacity, stack_size)
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self.capacity = capacity
        self.count = 0
        if self.is_heap():
            self.set_ptr(UnsafePointer[ElemT].alloc(Int(capacity)))

    fn __moveinit__(out self, owned other: Self):
        __mlir_op.`lit.ownership.mark_initialized`(
            __get_mvalue_as_litref(self.stack_data)
        )
        self.count = other.count
        self.capacity = other.capacity

        if other.is_heap():
            self.set_ptr(other.ptr())
        else:
            memcpy(self.stack_ptr(), other.stack_ptr(), Int(stack_size))

    fn __copyinit__(out self, other: Self):
        self = other.copy()

    fn copy(out self: Self, other: Self):
        self = Self(capacity=other.capacity)
        for i in range(len(other)):
            self.append(other[i])

    fn append(mut self, owned value: ElemT):
        if self.count == self.capacity:
            self._realloc(self.capacity * 2)
        self.ptr().offset(self.count).init_pointee_move(value^)
        self.count += 1

    fn is_heap(self) -> Bool:
        return self.capacity > stack_size

    fn stack_ptr[
        origin: Origin
    ](ref [origin]self) -> UnsafePointer[type=ElemT, mut = origin.mut, origin=origin]:
        return (
            UnsafePointer(to=self.stack_data)
            .bitcast[ElemT]()
            .origin_cast[mut = origin.mut, origin=origin]()
        )

    fn ptr(self) -> UnsafePointer[ElemT]:
        if self.is_heap():
            return self.stack_ptr().bitcast[UnsafePointer[ElemT]]()[]
        else:
            return self.stack_ptr()

    fn set_ptr(mut self, owned ptr: UnsafePointer[ElemT]):
        debug_assert(
            self.is_heap(),
            "Cannot set pointer for a IndexList that is not heap-allocated",
        )
        self.stack_ptr().bitcast[UnsafePointer[ElemT]]().init_pointee_move(ptr)

    fn __getitem__[T: Indexer](mut self, idx: T) -> ref [self] ElemT:
        debug_assert(Int(idx) < Int(self.count), "Index out of bounds for IndexList")
        return self.ptr().offset(idx)[]

    fn __getitem__[T: Indexer](self, idx: T) -> ElemT:
        debug_assert(Int(idx) < Int(self.count), "Index out of bounds for IndexList")
        return self.ptr().offset(idx)[]

    fn __setitem__[T: Indexer](mut self, idx: T, owned value: ElemT):
        debug_assert(Int(idx) <= Int(self.count), "Index out of bounds for IndexList")
        if Int(idx) == Int(self.count):
            self.append(value)
        else:
            self.ptr().offset(idx).init_pointee_move(value^)

    fn __del__(owned self):
        var ptr = self.ptr()
        for i in range(self.count):
            ptr.offset(i).destroy_pointee()
        if self.is_heap():
            ptr.free()

    fn __hash__(self) -> UInt:
        return hash(self.ptr().bitcast[UInt8](), Int(self.count) * sizeof[ElemT]())

    fn __eq__(self, other: Self) -> Bool:
        if self.count != other.count:
            return False
        for i in range(self.count):
            if self.ptr().offset(i)[] != other.ptr().offset(i)[]:
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn __len__(self) -> Int:
        return Int(self.count)

    fn _realloc(mut self, new_capacity: UInt32):
        debug_assert(new_capacity > self.capacity)
        var new_ptr = UnsafePointer[ElemT].alloc(Int(new_capacity))
        memcpy(new_ptr, self.ptr(), Int(self.count))
        if self.is_heap():
            self.ptr().free()
        self.set_ptr(new_ptr)
        self.capacity = new_capacity

    fn __iter__[
        origin: Origin
    ](ref [origin]self) -> _IndexListIter[ElemT, stack_size, origin]:
        return _IndexListIter[ElemT, stack_size, origin](self)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(ElemT.name_, "[")
        for i in range(self.count):
            if i > 0:
                writer.write(", ")
            writer.write(Int(self[i]))
        writer.write("]")


struct _IndexListIter[ElemT: NamedIndexT, stack_size: Int, origin: Origin](
    Copyable, Movable
):
    var index: Int
    var src: Pointer[IndexList[ElemT, stack_size], origin]

    fn __init__(out self, ref [origin]list: IndexList[ElemT, stack_size]):
        self.index = 0
        self.src = Pointer(to=list)

    fn __next__(mut self) -> ElemT:
        var idx = self.index
        self.index += 1
        return self.src[][idx]

    @always_inline
    fn __has_next__(self) -> Bool:
        return self.__len__() > 0

    fn __len__(self) -> Int:
        return len(self.src[]) - self.index
