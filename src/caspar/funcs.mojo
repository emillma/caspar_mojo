# from .callable import Callable, CallableVariant
from .val import Call
from .sysconfig import SymConfig
from os import abort
from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher

# from caspar.utils import hash


struct FuncInfo(EqualityComparable):
    var fname: String
    var n_args: Int
    var n_outs: Int
    var hash: UInt64

    fn __init__(out self, fname: String, n_args: Int, n_outs: Int):
        self.fname = fname
        self.n_args = n_args
        self.n_outs = n_outs

        self.hash = hash(self.fname)
        # hasher.update(self.n_args)
        # hasher.update(self.n_outs)
        # self.hash = hasher^.finish()

    # @parameter
    # for i in range(len(VariadicList(Ts))):
    # return hasher^.finish()
    #     self.hash = hash(self.fname, self.n_args, self.n_outs)

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.fname == other.fname
            and self.n_args == other.n_args
            and self.n_outs == other.n_outs
        )

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


trait Callable(Movable, Copyable, _HashableWithHasher, EqualityComparable):
    alias info: FuncInfo

    fn write_call[
        config: SymConfig, W: Writer
    ](self, call: Call[_, config], mut writer: W):
        ...


@value
struct Symbol(Callable):
    alias info = FuncInfo("Symbol", 0, 1)
    var name: String

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(self.name)

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)
        hasher.update(self.name)

    fn __eq__(self, other: Self) -> Bool:
        return self.name == other.name

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct ReadValue[size: Int](Callable):
    alias info = FuncInfo("ReadValue" + String(size), 0, size)
    var name: String

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(self.name)

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)
        hasher.update(self.name)

    fn __eq__(self, other: Self) -> Bool:
        return self.name == other.name

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct WriteValue[size: Int](Callable):
    alias info = FuncInfo("WriteValue" + String(size), size, 0)

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write("Write(")
        for i in range(size):
            writer.write(call.args(i))
            if i < size - 1:
                writer.write(", ")
        writer.write(")")

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)

    fn __eq__(self, other: Self) -> Bool:
        return True

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct Add(Callable):
    alias info = FuncInfo("Add", 2, 1)

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(call.args(0), " + ", call.args(1))

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct Mul(Callable):
    alias info = FuncInfo("Mul", -1, 1)

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(call.args(0), " * ", call.args(1))

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct StoreFloat(Callable):
    alias info = FuncInfo("StoreFloat", 0, 1)
    var data: Float64

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write(self.data)

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)
        hasher.update(self.data)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct StoreOne(Callable):
    alias info = FuncInfo("StoreOne", 0, 1)

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write("1")

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct StoreZero(Callable):
    alias info = FuncInfo("StoreZero", 0, 1)

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        writer.write("0")

    fn __hash__[H: _Hasher](self, mut hasher: H):
        hasher.update(Self.info.hash)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


@value
struct AnyFunc(Callable):
    alias info = FuncInfo("AnyFunc", -1, -1)

    fn write_call[sys: SymConfig, W: Writer](self, call: Call[_, sys], mut writer: W):
        constrained[False, "AnyFunc should not be used as a function type"]()

    fn __hash__[H: _Hasher](self, mut hasher: H):
        constrained[False, "AnyFunc should not be used as a function type"]()

    fn __eq__(self, other: Self) -> Bool:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return not self.__eq__(other)
