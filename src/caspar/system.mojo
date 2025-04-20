from sys.intrinsics import _type_is_eq
from .callables import Callable, DataVariant, StoreFloat, Symbol, Add
from .expr import ExprData, Expr
from .call import CallData, Call


struct SysConfig[*Ts: Callable]:
    @staticmethod
    fn get_callable_id[T: Callable]() -> Int:
        @parameter
        for i in range(len(VariadicList(Self.Ts))):

            @parameter
            if _type_is_eq[Self.Ts[i], T]():
                return i
        return -1


@value
struct System:
    alias sysConfig = SysConfig[StoreFloat, Symbol, Add]

    var _calls: List[CallData]
    var _exprs: List[ExprData]

    fn __init__(out self):
        self._calls = List[CallData]()
        self._exprs = List[ExprData]()

    fn call[
        FuncT: Callable
    ](
        mut self, *args: Expr[__origin_of(self)], data: DataVariant = None
    ) -> Call[__origin_of(self)]:
        """Creates a call and returns its ID."""
        debug_assert(len(args) == FuncT.n_args)
        debug_assert(data.isa[FuncT.DataT]())

        var call_id = len(self._calls)
        self._calls.append(
            CallData(
                n_args=FuncT.n_args,
                n_outs=FuncT.n_outs,
                data=data,
                func_id=self.sysConfig.get_callable_id[FuncT](),
                ger_repr=FuncT.get_repr,
            )
        )

        for arg in args:
            self._calls[call_id].arg_ids.append(arg.id)
            arg.add_use(call_id)

        for i in range(FuncT.n_outs):
            self._exprs.append(
                ExprData(
                    call_id=call_id,
                    out_idx=i,
                    use_ids=List[Int](capacity=0),
                )
            )
            self._calls[call_id].out_ids.append(len(self._exprs) - 1)
        return Call(Pointer(to=self), call_id)

    # fn symbol(mut self, name: String) -> ExprRef[__origin_of(self)]:
    #     """Creates a symbol and returns its ID."""
    #     var call = self.make_call(Symbol(name))
    #     return call._expr_ref(self, 0)
