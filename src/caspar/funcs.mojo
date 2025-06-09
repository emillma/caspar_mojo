# from .callable import Callable, CallableVariant
from .val import Call
from .sysconfig import SymConfig
from os import abort
from utils.static_tuple import StaticTuple
from caspar.compile import Context
from .utils import multihash
from memory import UnsafePointer
from caspar.collections import (
    ValIdx,
    OutIdx,
    IndexList,
)
from caspar.storage import SymbolStorage
from caspar.graph import Graph
from compile.reflection import get_type_name

# from caspar.utils import hash
alias Stack = StaticTuple[Float32, _]
from caspar import kernel_args


struct FuncInfo(EqualityComparable):
    var fname: StaticString
    var n_args: Int
    var n_outs: Int
    var hash: UInt

    fn __init__(
        out self,
        fname: StaticString,
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

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        ...

    fn data(self) -> Self.DataT:
        ...

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ...


@value
@register_passable("trivial")
struct Symbol(Callable):
    alias info = FuncInfo("Symbol", 0, 1)
    alias DataT = Tuple[StaticString, Int]
    var name: StaticString
    var idx: Int

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write(self.name, self.idx)

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.name, self.idx)

    fn __eq__(self, other: Self) -> Bool:
        return self.name == other.name and self.idx == other.idx

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return (self.name, self.idx)

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        constrained[False]()


@value
@register_passable("trivial")
struct ReadValue[size: Int = 1](Callable):
    alias info = FuncInfo("ReadValue" + String(size), 0, size)
    alias DataT = Tuple[Int, Int]

    var argidx: Int
    var offset: Int

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write("Read[arg", self.argidx, ",", self.offset, "]()")

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.argidx, self.offset)

    fn __eq__(self, other: Self) -> Bool:
        return self.argidx == other.argidx and self.offset == other.offset

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return (self.argidx, self.offset)

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ref arg = rebind[kernel_args.PtrArg[size]](context.arg[data[0]]())
        # print(get_type_name[__type_of(arg)]())

        @parameter
        for i in range(Self.size):
            # print(arg, arg.ptr, arg.ptr.offset(data[1] + i)[])
            context.set[outs[i]](arg.ptr.offset(data[1] + i)[])


@value
@register_passable("trivial")
struct WriteValue[size: Int = 1](Callable):
    alias info = FuncInfo("WriteValue" + String(size), size, 0)
    alias DataT = Tuple[Int, Int]

    var argidx: Int
    var offset: Int

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write("Write[arg", self.argidx, ",", self.offset, "](")
        for i in range(size):
            writer.write(call.arg(i))
            if i < size - 1:
                writer.write(", ")
        writer.write(")")

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.argidx, self.offset)

    fn __eq__(self, other: Self) -> Bool:
        return self.argidx == other.argidx and self.offset == other.offset

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return (self.argidx, self.offset)

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ref arg = rebind[kernel_args.PtrArg[size]](context.arg[data[0]]())

        @parameter
        for i in range(Self.size):
            arg.ptr.offset(data[1] + i)[] = context.get[args[i]]()


@value
@register_passable("trivial")
struct Add(Callable):
    alias info = FuncInfo("Add", 2, 1)
    alias DataT = NoneType

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write(call.arg(0), " + ", call.arg(1))

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        context.set[outs[0]](context.get[args[0]]() + context.get[args[1]]())


@value
@register_passable("trivial")
struct Mul(Callable):
    alias info = FuncInfo("Mul", -1, 1)
    alias DataT = NoneType

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write(call.arg(0), " * ", call.arg(1))

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ...


@value
@register_passable("trivial")
struct StoreFloat(Callable):
    alias info = FuncInfo("StoreFloat", 0, 1)
    alias DataT = Float64
    var value: Self.DataT

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write(self.value)

    fn __hash__(self) -> UInt:
        return multihash(Self.info.hash, self.value)

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return self.value

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ...


@value
@register_passable("trivial")
struct StoreOne(Callable):
    alias info = FuncInfo("StoreOne", 0, 1)
    alias DataT = NoneType

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write("1")

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ...


@value
@register_passable("trivial")
struct StoreZero(Callable):
    alias info = FuncInfo("StoreZero", 0, 1)
    alias DataT = NoneType

    fn write_call[W: Writer](self, call: Call, mut writer: W):
        writer.write("0")

    fn __hash__(self) -> UInt:
        return Self.info.hash

    fn __eq__(self, other: Self) -> Bool:
        return True  # Add is commutative, so all instances are equal

    fn __ne__(self, other: Self) -> Bool:
        return not self.__eq__(other)

    fn data(self) -> Self.DataT:
        return

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        ...


@value
@register_passable("trivial")
struct AnyFunc(Callable):
    alias info = FuncInfo("AnyFunc", -1, -1)
    alias DataT = NoneType

    fn write_call[W: Writer](self, call: Call, mut writer: W):
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

    fn data(self) -> Self.DataT:
        return

    @always_inline
    @staticmethod
    fn evaluate[
        args: IndexList[ValIdx],
        outs: IndexList[ValIdx],
        data: Self.DataT,
    ](mut context: Context):
        constrained[False, "AnyFunc should not be used as a function type"]()
