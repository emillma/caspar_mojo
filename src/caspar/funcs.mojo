# from .callable import Callable, CallableVariant
from .val import Call
from .sysconfig import SymConfig
from os import abort


trait Callable(Movable & Copyable):
    alias fname: String

    fn n_args(self) -> Int:
        ...

    @staticmethod
    fn n_outs() -> Int:
        ...

    fn write_call[
        config: SymConfig, W: Writer
    ](self, call: Call[_, config], mut writer: W):
        ...


trait Accessor:
    alias ArgT: AnyTrivialRegType


@value
struct ReadValue[size: Int](Callable, Accessor):
    alias fname = "ReadValue"
    alias ArgT = Float64
    var name: String

    fn n_args(self) -> Int:
        return 0

    @staticmethod
    fn n_outs() -> Int:
        return size

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(self.name)


@value
struct WriteValue[size: Int](Callable, Accessor):
    alias fname = "WriteValue"
    alias ArgT = Float64

    fn n_args(self) -> Int:
        return size

    @staticmethod
    fn n_outs() -> Int:
        return 0

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write("Write(")
        for i in range(size):
            writer.write(call.args(i))
            if i < size - 1:
                writer.write(", ")
        writer.write(")")


@value
struct Add(Callable):
    alias fname = "Add"

    fn n_args(self) -> Int:
        return 2

    @staticmethod
    fn n_outs() -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(call.args(0), " + ", call.args(1))


@value
struct Mul(Callable):
    alias fname = "Mul"

    fn n_args(self) -> Int:
        return 2

    @staticmethod
    fn n_outs() -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(call.args(0), " * ", call.args(1))


@value
struct StoreFloat(Callable):
    alias fname = "StoreFloat"
    var data: Float64

    fn n_args(self) -> Int:
        return 0

    @staticmethod
    fn n_outs() -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(self.data)


@value
struct StoreOne(Callable):
    alias fname = "StoreOne"

    fn n_args(self) -> Int:
        return 0

    @staticmethod
    fn n_outs() -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write("1")


@value
struct StoreZero(Callable):
    alias fname = "StoreZero"

    fn n_args(self) -> Int:
        return 0

    @staticmethod
    fn n_outs() -> Int:
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write("0")


@value
struct AnyFunc(Callable):
    alias fname = "AnyFunc"

    fn n_args(self) -> Int:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return -1

    @staticmethod
    fn n_outs() -> Int:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return 1

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        constrained[False, "AnyFunc should not be used as a function type"]()
