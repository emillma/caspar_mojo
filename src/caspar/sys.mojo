from .func_types import Callable, Symbol, Func


struct System:
    var calls: List[Call]

    fn __init__(out self):
        self.calls = List[Call]()

    fn call[
        funcT: Callable
    ](mut self, func: funcT, *args: ExprRef[__origin_of(self)]) -> Int:
        """Creates a call and returns its ID."""
        var call = Call(
            func=func,
            args=args,
            call_id=len(self.calls),
        )
        self.calls.append(call)
        return len(self.calls) - 1

    fn symbol(mut self, name: String) -> ExprRef[__origin_of(self)]:
        """Creates a symbol and returns its ID."""
        return ExprRef(self, self.call(Symbol(name)), 0)


@value
struct Call:
    var func: Func
    var args: List[ExprId]

    fn __init__[
        funcT: Callable, origin: MutableOrigin
    ](
        out self,
        func: funcT,
        args: VariadicListMem[ExprRef[origin]],
        call_id: Int,
    ):
        self.func = func
        self.args = List[ExprId](capacity=len(args))
        for arg in args:
            self.args.append(arg[].id)


@value
@register_passable("trivial")
struct ExprId:
    var func: Int
    var out: Int


@value
struct ExprRef[
    sys_origin: MutableOrigin,
](Writable):
    var sysref: Pointer[System, sys_origin]
    var id: ExprId

    fn __init__(
        out self,
        ref [sys_origin]sys: System,
        call_id: Int,
        out_idx: Int,
    ):
        self.sysref = Pointer(to=sys)
        self.id = ExprId(call_id, out_idx)

    fn write_to[T: Writer](self, mut writer: T):
        ("caspar").write_to(writer)
