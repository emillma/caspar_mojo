from memory import UnsafePointer
from .callable import Callable, CallableVariant
from caspar.functions import Symbol, Add
from .sysconfig import SymConfig
from sys.intrinsics import _type_is_eq


struct RcPointerInner[T: Movable]:
    var refcount: Int
    var payload: T

    @implicit
    fn __init__(out self, owned value: T):
        self.refcount = 1
        self.payload = value^

    fn add_ref(mut self):
        self.refcount += 1

    fn drop_ref(mut self) -> Bool:
        self.refcount -= 1
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

    @no_inline
    fn __del__(owned self):
        if self._inner[].drop_ref():
            self._inner.destroy_pointee()
            self._inner.free()

    fn __getitem__(self) -> ref [self] T:
        return self._inner[].payload


# @value
struct CallData[sys: SymConfig](Movable & Copyable):
    alias static_arg_size = 4
    alias static_out_size = 4

    var func: CallableVariant[sys]
    var args: List[Expr[sys]]  # TODO: Use small-vector optimized collection

    @staticmethod
    fn __init__(
        out self: Self,
        owned func: CallableVariant[sys],
        owned args: List[Expr[sys]],
    ):
        debug_assert(len(args) == func.n_args(), "Invalid number of arguments")
        self.args = args^
        self.func = func^

    fn __copyinit__(out self, existing: Self):
        self.args = existing.args
        self.func = existing.func

    fn __moveinit__(out self, owned existing: Self):
        self.args = existing.args^
        self.func = existing.func^


struct Call[sys: SymConfig]:
    var _data: RcPointer[CallData[sys]]

    fn __init__(
        out self,
        owned func: CallableVariant[sys],
        owned args: List[Expr[sys]] = List[Expr[sys]](),
    ):
        self._data = RcPointer(CallData[sys](func^, args^))

    fn __copyinit__(out self, existing: Self):
        self._data = existing._data

    fn __moveinit__(out self, owned existing: Self):
        self._data = existing._data^

    fn __getitem__(self) -> ref [self._data] CallData[sys]:
        return self._data[]

    fn __getitem__(self, idx: Int) -> Expr[sys]:
        return Expr[sys](self, idx)

    fn write_to[W: Writer](self, mut writer: W):
        self[].func.write_call(self, writer)

    fn args(self) -> ref [self._data[].args] List[Expr[sys]]:
        return self._data[].args

    fn args(self, idx: Int) -> ref [self._data[].args] Expr[sys]:
        return self._data[].args[idx]


@value
struct Expr[sys: SymConfig](CollectionElement, Writable):
    var call: Call[sys]
    var out_idx: Int

    fn write_to[W: Writer](self, mut writer: W):
        self.call.write_to(writer)
        if self.call[].func.n_outs() > 1:
            writer.write("[", self.out_idx, "]")

    fn args(self) -> ref [self.call[].args] List[Self]:
        return self.call.args()

    fn args(self, idx: Int) -> ref [self.call[].args] Self:
        return self.call.args(idx)
