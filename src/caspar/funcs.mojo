# from .callable import Callable, CallableVariant
from .val import Call
from .sysconfig import SymConfig
from os import abort
from utils.static_tuple import StaticTuple
from .context import Context
from .utils import multihash
from memory import UnsafePointer

# from caspar.utils import hash
alias Stack = StaticTuple[Float32, _]


struct FuncInfo(EqualityComparable):
    var fname: String
    var n_args: Int
    var n_outs: Int
    var hash: UInt

    fn __init__(
        out self,
        fname: String,
        n_args: Int,
        n_outs: Int,
    ):
        self.fname = fname
        self.n_args = n_args
        self.n_outs = n_outs

        self.hash = hash(self.fname)

    fn __eq__(self, other: Self) -> Bool:
        return (
            self.fname == other.fname
            and self.n_args == other.n_args
            and self.n_outs == other.n_outs
        )

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)


trait Callable(Copyable, Movable, KeyElement):
    alias info: FuncInfo
    alias DataT: AnyType

    fn write_call[
        config: SymConfig, W: Writer
    ](self, call: Call[config], mut writer: W):
        ...

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct Symbol(Callable):
    alias info = FuncInfo("Symbol", 0, 1)
    alias DataT = StaticString
    var name: Self.DataT

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write(self.name)

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.name)

    fn __eq__(self, other: Self) -> Bool:
        return self.name == other.name

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct ReadValue[size: Int = 1](Callable):
    alias info = FuncInfo("ReadValue" + String(size), 0, size)
    alias DataT = Tuple[Int, Int]

    var argname: StaticString
    var offset: Int

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write(self.argname)

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.argname, self.offset)

    fn __eq__(self, other: Self) -> Bool:
        return self.argname == other.argname and self.offset == other.offset

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct WriteValue[size: Int = 1](Callable):
    alias info = FuncInfo("WriteValue" + String(size), size, 0)
    alias DataT = Tuple[String, Int]

    var argname: StaticString
    var offset: Int

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write("Write(", self.argname, ", ")
        for i in range(size):
            writer.write(call.args(i))
            if i < size - 1:
                writer.write(", ")
        writer.write(")")

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.argname, self.offset)

    fn __eq__(self, other: Self) -> Bool:
        return self.argname == other.argname and self.offset == other.offset

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct Add(Callable):
    alias info = FuncInfo("Add", 2, 1)
    alias DataT = NoneType

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write(call.args(0), " + ", call.args(1))

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct Mul(Callable):
    alias info = FuncInfo("Mul", -1, 1)
    alias DataT = NoneType

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write(call.args(0), " * ", call.args(1))

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct StoreFloat(Callable):
    alias info = FuncInfo("StoreFloat", 0, 1)
    alias DataT = Float64
    var value: Self.DataT

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write(self.value)

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.value)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct StoreOne(Callable):
    alias info = FuncInfo("StoreOne", 0, 1)
    alias DataT = NoneType

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write("1")

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct StoreZero(Callable):
    alias info = FuncInfo("StoreZero", 0, 1)
    alias DataT = NoneType

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        writer.write("0")

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        ...


@value
@register_passable("trivial")
struct AnyFunc(Callable):
    alias info = FuncInfo("AnyFunc", -1, -1)
    alias DataT = NoneType

    fn write_call[conf: SymConfig, W: Writer](self, call: Call[conf], mut writer: W):
        constrained[False, "AnyFunc should not be used as a function type"]()

    fn __hash__(self) -> UInt:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        constrained[False, "AnyFunc should not be used as a function type"]()
        return not self.__eq__(other)

    @always_inline
    @staticmethod
    fn evaluate[
        CT: Context, //, args: List[Int], outs: List[Int], data: Self.DataT
    ](mut context: CT):
        constrained[False, "AnyFunc should not be used as a function type"]()
