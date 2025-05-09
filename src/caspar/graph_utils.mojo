from .expr import Call


@register_passable("trivial")
struct Index[T: StringLiteral](Indexer):
    var value: Int

    @implicit
    fn __init__(out self, value: Int):
        self.value = value

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


alias FuncTypeIdx = Index["FuncTypeIdx"]
alias CallInstanceIdx = Index["CallInstanceIdx"]


@value
@register_passable("trivial")
struct CallIdx:
    var type: FuncTypeIdx
    var instance: CallInstanceIdx

    @implicit
    fn __init__(out self, other: Call):
        self = other.idx

    fn __init__(out self, type: FuncTypeIdx, instance: CallInstanceIdx):
        self.type = type
        self.instance = instance


alias ExprIdx = Index["ExprIdx"]
alias OutIdx = Index["OutIdx"]

alias StackList = List


struct CallTable[config: SymConfig]:
    var ptrs: InlineArray[UnsafePointer[Byte], config.n_funcs, run_destructors=True]
    var counts: InlineArray[Int, config.n_funcs, run_destructors=True]
    var capacities: InlineArray[Int, config.n_funcs, run_destructors=True]
    var strides: InlineArray[Int, config.n_funcs, run_destructors=True]

    fn __init__(out self):
        self.ptrs = __type_of(self.ptrs)(uninitialized=True)
        self.counts = __type_of(self.counts)(uninitialized=True)
        self.capacities = __type_of(self.capacities)(uninitialized=True)
        self.strides = __type_of(self.strides)(uninitialized=True)
        alias init_size = 100

        @parameter
        for i in config.funcs.range():
            alias CallT = CallMem[config.funcs.Ts[i], config]
            self.ptrs[i] = UnsafePointer[CallT].alloc(init_size).bitcast[Byte]()
            self.counts.unsafe_ptr().offset(i).init_pointee_move(0)
            self.capacities.unsafe_ptr().offset(i).init_pointee_move(init_size)
            self.strides.unsafe_ptr().offset(i).init_pointee_move(sizeof[CallT]())

    fn __del__(owned self):
        @parameter
        for i in config.funcs.range():
            alias CallT = CallMem[config.funcs.Ts[i], config]
            for j in range(self.counts[i]):
                self.ptrs[i].bitcast[CallT]().destroy_pointee()
            self.ptrs[i].free()

    fn ptr[
        FT: Callable
    ](mut self, idx: CallInstanceIdx) -> UnsafePointer[
        CallMem[FT, config], origin = __origin_of(self.ptrs)
    ]:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.ptrs[ftype_idx].bitcast[CallMem[FT, config]]().offset(idx)

    fn ptr(
        mut self, idx: CallIdx
    ) -> UnsafePointer[CallMem[AnyFunc, config], origin = __origin_of(self.ptrs)]:
        return (
            self.ptrs[idx.type]
            .offset(Int(idx.instance) * self.strides[idx.type])
            .bitcast[CallMem[AnyFunc, config]]()
        )

    fn add[FT: Callable](mut self, owned call_mem: CallMem[FT, config]):
        alias ftype_idx = Self.ftype_idx[FT]()
        debug_assert(
            self.counts[ftype_idx] < self.capacities[ftype_idx],
            "CallStorage is full for function type",
        )
        self.ptr[FT](self.counts[ftype_idx]).init_pointee_copy(call_mem^)
        self.counts[ftype_idx] += 1

    @staticmethod
    fn call_idx[FT: Callable](idx: CallInstanceIdx) -> CallIdx:
        return CallIdx(Self.ftype_idx[FT](), idx)

    @staticmethod
    fn ftype_idx[FT: Callable]() -> Int:
        return config.funcs.func_to_idx[FT]()

    fn count[FT: Callable](self) -> Int:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.counts[ftype_idx]

    fn capacity[FT: Callable](self) -> Int:
        alias ftype_idx = Self.ftype_idx[FT]()
        return self.capacities[ftype_idx]
