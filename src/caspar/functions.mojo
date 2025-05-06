from .callable import Callable, CallableVariant
from .expr import CallRef
from .sysconfig import SymConfig


@value
struct Symbol(Callable):
    var data: String

    fn n_args(self) -> Int:
        return 0

    fn n_outs(self) -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: CallRef[sys], mut writer: W):
        writer.write(self.data)

    fn __eq__(self, other: Self) -> Bool:
        return self.data == other.data

    fn __hash__(self) -> UInt:
        return hash(self.data)


@value
struct Add(Callable):
    fn n_args(self) -> Int:
        return 2

    fn n_outs(self) -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: CallRef[sys], mut writer: W):
        call.args(0).write_to(writer)
        writer.write(" + ")
        call.args(1).write_to(writer)

    fn __eq__(self, other: Self) -> Bool:
        return True

    fn __hash__(self) -> UInt:
        return 0
