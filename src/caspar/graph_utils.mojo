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

    fn __init__(out self, type: FuncTypeIdx, instance: CallInstanceIdx):
        self.type = type
        self.instance = instance


alias ExprIdx = Index["ExprIdx"]
alias OutIdx = Index["OutIdx"]

alias StackList = List
