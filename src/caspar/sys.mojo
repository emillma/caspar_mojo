from .func_types import FuncT, FuncVariant, Symbol
from .sys_components import CallMem, Expr

# from sys import alignof, sizeof


struct System:
    var calls: List[CallMem]

    fn __init__(out self):
        self.calls = List[CallMem]()

    fn call[
        origin: MutableOrigin
    ](ref [origin]self, func: FuncVariant, *args: Expr[origin],) -> Int:
        print("hello")
        var call = CallMem(func=func, args=args, call_id=len(self.calls))
        # self.calls.append(call)
        return len(self.calls) - 1

    fn symbol(mut self, name: String) -> Expr[__origin_of(self)]:
        _ = self.call(Symbol(name=name))
        # return Expr(self, , 0)
        return Expr(self, 2, 0)
