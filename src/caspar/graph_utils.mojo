from .val import Call
from memory import UnsafePointer
from .sysconfig import SymConfig
from .funcs import Callable, AnyFunc
from .graph import Graph, CallMem, ValMem
from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher
from sys.intrinsics import sizeof


@fieldwise_init("implicit")
@register_passable("trivial")
struct NamedIndex[T: StringLiteral](Indexer, _HashableWithHasher, Hashable):
    var value: Int

    @always_inline
    fn __index__(self) -> __mlir_type.index:
        return self.value.__index__()

    @always_inline
    fn __int__(self) -> Int:
        return self.value

    @always_inline
    fn __eq__(self, other: Self) -> Bool:
        return self.value == other.value

    @always_inline
    fn __req__(self, other: Self) -> Bool:
        return self.value == other.value

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(self.value)

    fn __hash__(self) -> UInt:
        var hasher = default_hasher()
        hasher.update(self.value)
        return UInt(hasher^.finish())


alias FuncTypeIdx = NamedIndex["FuncTypeIdx"]
alias CallInstanceIdx = NamedIndex["CallInstanceIdx"]
alias ValIdx = NamedIndex["ValIdx"]
alias OutIdx = NamedIndex["OutIdx"]


@value
@register_passable("trivial")
struct CallIdx(_HashableWithHasher):
    var type: FuncTypeIdx
    var instance: CallInstanceIdx

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(self.type)
        hasher.update(self.instance)


struct StackList[ElemT: _HashableWithHasher & Indexer, stack_size: Int = 4](
    _HashableWithHasher
):
    var capacity: UInt32
    var count: UInt32
    var stack_data: InlineArray[ElemT, stack_size, run_destructors=False]

    fn __init__(out self, capacity: Int):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self.capacity = capacity
        if self.is_heap():
            self.set_ptr(UnsafePointer[ElemT].alloc(capacity))
        self.count = 0
        self.capacity = capacity

    fn __moveinit__(out self, owned other: Self):
        debug_assert(
            other.count == other.capacity,
            "Cannot move a StackList with non-zero count",
        )
        if other.is_heap():
            __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
            self.set_ptr(other.ptr())
        else:
            self.stack_data = other.stack_data.copy()
        self.count = other.count
        self.capacity = other.capacity

    fn append(mut self, owned value: ElemT):
        debug_assert(
            self.count < self.capacity,
            "Cannot append to a StackList with full capacity",
        )
        self.ptr().offset(self.count).init_pointee_move(value^)
        self.count += 1

    fn is_heap(self) -> Bool:
        return self.capacity > stack_size

    fn ptr(self) -> UnsafePointer[ElemT]:
        if self.is_heap():
            return self.stack_data.unsafe_ptr().bitcast[UnsafePointer[ElemT]]()[]
        else:
            return self.stack_data.unsafe_ptr()

    fn set_ptr(mut self, owned ptr: UnsafePointer[ElemT]):
        debug_assert(
            self.is_heap(),
            "Cannot set pointer for a StackList that is not heap-allocated",
        )
        self.stack_data.unsafe_ptr().bitcast[UnsafePointer[ElemT]]().init_pointee_move(
            ptr
        )

    fn __getitem__[T: Indexer](self, idx: T) -> ref [self] ElemT:
        debug_assert(Int(idx) < Int(self.count), "Index out of bounds for StackList")
        return self.ptr().offset(idx)[]

    fn __del__(owned self):
        var ptr = self.ptr()
        for i in range(self.count):
            ptr.offset(i).destroy_pointee()
        if self.is_heap():
            ptr.free()

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(self.capacity)
        hasher.update(self.count)
        hasher._update_with_bytes(
            self.ptr().bitcast[UInt8](),
            Int(self.count) * sizeof[ElemT](),
        )
