from memory import UnsafePointer
from .callable import Callable, CallableVariant
from caspar.functions import Symbol, Add


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
struct CallData[*Ts: Callable](Movable & Copyable):
    alias Expr = Expr[*Ts]

    alias static_arg_size = 4
    alias static_out_size = 4

    var func: CallableVariant[*Ts]
    var args: List[Self.Expr]

    @staticmethod
    fn __init__(
        out self: Self,
        owned func: CallableVariant[*Self.Ts],
        owned args: List[Self.Expr],
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


struct Call[*Ts: Callable]:
    alias CallVariant = CallableVariant[*Ts]
    alias CallData = CallData[*Ts]
    alias Expr = Expr[*Ts]

    var _data: RcPointer[Self.CallData]

    fn __init__(
        out self,
        owned func: Self.CallVariant,
        owned args: List[Self.Expr] = List[Self.Expr](),
    ):
        self._data = RcPointer(Self.CallData(func^, args^))

    fn __copyinit__(out self, existing: Self):
        self._data = existing._data

    fn __moveinit__(out self, owned existing: Self):
        self._data = existing._data^

    fn __getitem__(self) -> ref [self._data] Self.CallData:
        return self._data[]

    fn __getitem__(self, idx: Int) -> Self.Expr:
        return Self.Expr(self, idx)


@value
struct Expr[*Ts: Callable](CollectionElement):
    alias Call = Call[*Ts]

    var call: Self.Call
    var out_idx: Int

    fn __str__(self) -> String:
        var arg_strings = List[String](capacity=self.call[].func.n_args())
        for arg in self.args():
            arg_strings.append(String(arg[]))
        return self.call[].func.repr(arg_strings)

    fn __add__(self, other: Self) -> Self:
        return Self.Call(Add(), List(self, other))[0]

    fn args(self) -> ref [self.call[].args] List[Self]:
        return self.call[].args

    fn args(self, idx: Int) -> ref [self.call[].args] Self:
        return self.call[].args[idx]

    fn __copyinit__(out self, existing: Self):
        self.call = existing.call
        self.out_idx = existing.out_idx

    fn __moveinit__(out self, owned existing: Self):
        self.call = existing.call^
        self.out_idx = existing.out_idx

    fn print(self) -> String:
        return self.call[].func.print(List[Self]())
