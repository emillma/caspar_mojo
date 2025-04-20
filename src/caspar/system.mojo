from sys.intrinsics import _type_is_eq
from .callables import Callable, DataVariant, StoreFloat, Symbol, Add
from .expr import ExprData, ExprRef
from .call import CallData, CallRef
from .owned_list import OwnedList


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

    var foo: OwnedList[CallData]

    fn __init__(out self):
        self._calls = List[CallData]()
        self._exprs = List[ExprData]()
        self.foo = OwnedList[CallData]()

    fn __getitem__[
        origin: MutableOrigin
    ](ref [origin]self, expr: ExprRef[origin]) -> ref [self._exprs] ExprData:
        """Returns the expression data."""
        return self._exprs[expr.id]

    fn __getitem__[
        origin: MutableOrigin
    ](ref [origin]self, call: CallRef[origin]) -> ref [self._calls] CallData:
        """Returns the call data."""
        return self._calls[call.id]

    fn call[
        FuncT: Callable
    ](
        mut self, *args: ExprRef[__origin_of(self)], data: DataVariant = None
    ) -> CallRef[__origin_of(self)]:
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
                get_repr=FuncT.get_repr,
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
        return CallRef(Pointer(to=self), call_id)

    fn __del__(owned self):
        self.foo.destroy()

    # fn symbol(mut self, name: String) -> ExprRef[__origin_of(self)]:
    #     """Creates a symbol and returns its ID."""
    #     var call = self.make_call(Symbol(name))
    #     return call._expr_ref(self, 0)
