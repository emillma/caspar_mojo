from .expr import ExprMem, ExprRef, Expr
from .call import CallMem, Call
from .func_types import FuncT, Store, Add, Symbol, FuncSet, FuncSetDefault


struct SystemBase[funcSet: FuncSet]:
    alias ExprMem = ExprMem[funcSet]
    alias ExprRef = ExprRef[funcSet]
    alias Expr = Expr[funcSet, _]
    alias CallMem = CallMem[funcSet]
    alias Call = Call[funcSet]

    var calls: List[Self.CallMem]

    fn __init__(out self):
        self.calls = List[Self.CallMem]()

    fn call[
        funcT: FuncT
    ](
        mut self,
        *args: Self.Expr[__origin_of(self.calls)],
        data: Self.CallMem.dataT,
    ) -> Self.Call[__origin_of(self), __origin_of(self.calls)]:
        alias n_args = funcSet.get_n_args[funcT]()

        var arglist: List[Self.ExprRef] = List[Self.ExprRef](capacity=n_args)

        @parameter
        for i in range(n_args):
            arglist.append(Self.ExprRef(args[i]))

        self.calls.append(CallMem[funcSet].to[funcT](args=arglist, data=data))
        return Self.Call[__origin_of(self)](self.calls[-1])

    # fn symbol(
    #     mut self, name: String
    # ) -> Self.Call[__origin_of(self), __origin_of(self.calls)]:
    #     return self.call[Store](data=name)[0]


alias System = SystemBase[FuncSetDefault()]
