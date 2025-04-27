from .callable import Callable, CallableVariant
from .expr import Expr, Call
from .sysconfig import SymConfig


@value
struct Symbol(Callable):
    var data: String

    fn n_args(self) -> Int:
        return 0

    fn n_outs(self) -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[sys], mut writer: W):
        writer.write(self.data)


@value
struct Add(Callable):
    fn n_args(self) -> Int:
        return 2

    fn n_outs(self) -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[sys], mut writer: W):
        call.args(0).write_to(writer)
        writer.write(" + ")
        call.args(1).write_to(writer)
