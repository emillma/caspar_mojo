# from .callable import Callable, CallableVariant
from .expr import Call
from .sysconfig import SymConfig


trait Callable(Movable & Copyable):
    fn n_args(self) -> Int:
        ...

    fn n_outs(self) -> Int:
        ...

    fn write_call[
        config: SymConfig, W: Writer
    ](self, call: Call[config], mut writer: W):
        ...


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
        # call.args(0).write_to(writer)
        writer.write(" + ")
        # call.args(1).write_to(writer)


@value
struct AnyFunc[config: SymConfig](Callable):
    var _n_args: Int
    var _n_outs: Int
    var _func_idx: Int
    var _repr: String

    @implicit
    fn __init__[FT: Callable](out self, other: FT):
        self._n_args = other.n_args()
        self._n_outs = other.n_outs()
        self._func_idx = config.callables.func_to_idx[FT]()
        self._repr = "Any()"

    fn n_args(self) -> Int:
        return self._n_args

    fn n_outs(self) -> Int:
        return self._n_outs

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[sys], mut writer: W):
        writer.write(self._repr)
