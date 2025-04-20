from .func_types import Callable, Symbol, Func


struct System:
    var calls: List[Call]
    var exprs: List[Expr]

    fn __init__(out self):
        self.calls = List[Call]()
        self.exprs = List[Expr]()

    fn __copyinit__(out self, other: System):
        self.calls = other.calls
        self.exprs = other.exprs

    fn get_expr(self, id: Int) -> ref [self.exprs] Expr:
        """Returns an expression reference."""
        return self.exprs[id]

    fn get_call(self, id: Int) -> ref [self.calls] Call:
        """Returns a call reference."""
        return self.calls[id]

    fn make_call[
        funcT: Callable
    ](mut self, func: funcT, *args: ExprRef[__origin_of(self)]) -> ref [
        self.calls
    ] Call:
        """Creates a call and returns its ID."""
        self.calls.append(Call(func, len(self.calls)))
        for arg in args:
            self.calls[-1].args_ids.append(arg[].id)
            self.exprs[arg[].id].use_ids.append(self.calls[-1].id)

        @parameter
        for i in range(funcT.n_outs):
            self.exprs.append(
                Expr(len(self.exprs), self.calls[-1].id, i, List[Int]())
            )
            self.calls[-1].out_ids.append(self.exprs[-1].id)
        return self.calls[-1]

    fn symbol(mut self, name: String) -> ExprRef[__origin_of(self)]:
        """Creates a symbol and returns its ID."""
        var call = self.make_call(Symbol(name))
        return call._expr_ref(self, 0)


@value
struct Call:
    var func: Func
    var id: Int
    var args_ids: List[Int]
    var out_ids: List[Int]

    fn __init__(out self, func: Func, id: Int):
        self.func = func
        self.id = id
        self.args_ids = List[Int]()
        self.out_ids = List[Int]()

    fn _expr_ref(self, mut sys: System, idx: Int) -> ExprRef[__origin_of(sys)]:
        """Returns an expression reference."""
        return ExprRef(sys, self.out_ids[idx])


@value
struct Expr:
    var id: Int
    var call_id: Int
    var out_idx: Int
    var use_ids: List[Int]


@value
struct ExprRef[sys_origin: MutableOrigin]:
    var sysref: Pointer[System, sys_origin]
    var id: Int

    fn __init__(out self, ref [sys_origin]sys: System, id: Int):
        self.sysref = Pointer(to=sys)
        self.id = id
