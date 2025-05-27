# from .callable import Callable, CallableVariant
from .val import Call
from .sysconfig import SymConfig
from os import abort
from hashlib._hasher import _HashableWithHasher, _Hasher


trait Callable(Movable, Copyable, _HashableWithHasher):
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


fn get_signature[H: _Hasher, *Ts: _HashableWithHasher](*args: *Ts) -> UInt64:
    """Generates a signature string for the given arguments."""
    var hasher = H()

    @parameter
    for i in range(len(VariadicList(Ts))):
        hasher.update(args[i])
    return hasher^.finish()


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname), Self.size)
        hasher.update(signature)
        hasher.update(self.name)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname), Self.size)
        hasher.update(signature)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname))
        hasher.update(signature)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname))
        hasher.update(signature)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname))
        hasher.update(signature)
        hasher.update(self.data)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname))
        hasher.update(signature)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        alias signature = get_signature[H](String(Self.fname))
        hasher.update(signature)


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

    fn __hash__[H: _Hasher](self, mut hasher: H):
        constrained[False, "AnyFunc should not be used as a function type"]()
