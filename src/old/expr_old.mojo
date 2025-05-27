from memory import UnsafePointer
from .callable import Callable, CallableVariant
from caspar.functions import Symbol, Add
from .sysconfig import SymConfig
from sys.intrinsics import _type_is_eq
from .utils import multihash


struct RcPointerInner[T: Movable]:
    var refcount: Int
    var payload: T

    @implicit
    fn __init__(out self, owned value: T):
        self.refcount = 1
        self.payload = value^
        # print(
        #     "Initializing refcount to ",
        #     self.refcount,
        #     UnsafePointer(to=self).origin_cast[origin=MutableAnyOrigin](),
        # )

    fn add_ref(mut self):
        self.refcount += 1
        # print(
        #     "Increasing refcount to ",
        #     self.refcount,
        #     UnsafePointer(to=self).origin_cast[origin=MutableAnyOrigin](),
        # )

    fn drop_ref(mut self) -> Bool:
        self.refcount -= 1
        # print(
        #     "Dropping refcount to ",
        #     self.refcount,
        #     UnsafePointer(to=self).origin_cast[origin=MutableAnyOrigin](),
        # )
        debug_assert(
            self.refcount >= 0,
            "Refcount should never be negative",
            UnsafePointer(to=self).origin_cast[origin=MutableAnyOrigin](),
        )
        return self.refcount == 0


struct RcPointer[T: Movable]:
    alias InnerT = RcPointerInner[T]
    var _inner: UnsafePointer[Self.InnerT]

    @implicit
    fn __init__(out self, owned value: T):
        self._inner = UnsafePointer[Self.InnerT].alloc(1)
        __get_address_as_uninit_lvalue(self._inner.address) = Self.InnerT(value^)

    fn __copyinit__(out self, existing: Self):
        existing._inner[].add_ref()
        self._inner = existing._inner

    fn __moveinit__(out self, owned existing: Self):
        self._inner = existing._inner

    # @no_inline
    fn __del__(owned self):
        if self._inner[].drop_ref():
            self._inner.destroy_pointee()
            self._inner.free()

    fn __getitem__(self) -> ref [self] T:
        return self._inner[].payload


# @value
struct CallData[sys: SymConfig](Movable):
    alias static_arg_size = 4
    alias static_out_size = 4

    var func: CallableVariant[sys]
    var args: List[Val[sys]]  # TODO: Use small-vector optimized collection

    @staticmethod
    fn __init__(
        out self: Self,
        owned func: CallableVariant[sys],
        owned args: List[Val[sys]],
    ):
        debug_assert(len(args) == func.n_args(), "Invalid number of arguments")
        self.args = args^
        self.func = func^

    fn __moveinit__(out self, owned existing: Self):
        self.args = existing.args^
        self.func = existing.func^


struct Call[sys: SymConfig]:
    var _data: RcPointer[CallData[sys]]

    fn __init__(
        out self,
        owned func: CallableVariant[sys],
        owned args: List[Val[sys]] = List[Val[sys]](),
    ):
        self._data = RcPointer(CallData[sys](func^, args^))

    fn __copyinit__(out self, existing: Self):
        self._data = existing._data

    fn __moveinit__(out self, owned existing: Self):
        self._data = existing._data^

    fn func(self) -> ref [self._data[].func] CallableVariant[sys]:
        return self._data[].func

    fn args(self) -> ref [self._data[].args] List[Val[sys]]:
        return self._data[].args

    fn args(self, idx: Int) -> ref [self._data[].args] Val[sys]:
        return self._data[].args[idx]

    fn __getitem__(owned self, idx: Int) -> Val[sys]:
        return Val[sys](self^, idx)

    fn write_to[W: Writer](self, mut writer: W):
        self.func().write_call(self, writer)

    fn __eq__(self, other: Self) -> Bool:
        if self.func() != self.func():
            return False
        for i in range(len(self.args())):
            if self.args(i) != other.args(i):
                return False
        return True

    fn __ne__(self, other: Self) -> Bool:
        if self.func() != self.func():
            return True
        for i in range(len(self.args())):
            if self.args(i) != other.args(i):
                return True
        return False


@value
struct Val[sys: SymConfig](Movable & Copyable, Writable):
    var call: Call[sys]
    var out_idx: Int

    fn __moveinit__(out self, owned existing: Self):
        self.call = existing.call^
        self.out_idx = existing.out_idx

    fn write_to[W: Writer](self, mut writer: W):
        self.call.write_to(writer)
        if self.call.func().n_outs() > 1:
            writer.write("[", self.out_idx, "]")

    fn __add__(self, other: Self) -> Self:
        return Call[sys](Add(), List[Self](self, other))[0]

    fn __eq__(self, other: Self) -> Bool:
        return self.call == other.call and self.out_idx == other.out_idx

    fn __ne__(self, other: Self) -> Bool:
        return self.call != other.call or self.out_idx != other.out_idx
