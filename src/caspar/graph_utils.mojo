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


alias CallIdx = Index["callmem"]
alias ExprIdx = Index["exprmem"]
alias OutIdx = Index["output"]
alias FuncTypeIdx = Index["functype"]

alias StackList = List
