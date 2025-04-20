from sys.intrinsics import _type_is_eq
from memory import UnsafePointer
from os import abort
from utils import Variant
from sys import alignof, sizeof
from .sys_components import CallMem
from builtin.range import _ZeroStartingRange


trait Callable(CollectionElement):
    alias n_outs: Int
    alias n_args: Int


@register_passable("trivial")
struct StoreFloat(Callable):
    alias n_args = 0
    alias n_outs = 1
    var data: Float64


@value
struct Symbol(Callable):
    alias n_args = 0
    alias n_outs = 1
    var name: String


@register_passable("trivial")
struct Add(Callable):
    alias n_args = 2
    alias n_outs = 1

    fn op_repr(self, args: List[String]) -> String:
        return args[0] + " + " + args[1]


alias Func = FuncVariant[StoreFloat, Symbol, Add]


@value
struct FuncVariant[*Ts: Callable]:
    var _type_id: Int
    var _data: InlineArray[Byte, Self.largest_size()]

    fn n_args(self) -> Int:
        @parameter
        for i in Self.trange():
            if self._type_id == i:
                return Self.Ts[i].n_args

    @staticmethod
    fn trange() -> _ZeroStartingRange:
        return range(len(VariadicList(Self.Ts)))

    @staticmethod
    fn supports[T: Callable]() -> Bool:
        @parameter
        for i in range(len(VariadicList(Self.Ts))):

            @parameter
            if _type_is_eq[Self.Ts[i], T]():
                return True
        return False

    @staticmethod
    fn type_id_of[T: Callable]() -> Int:
        constrained[Self.supports[T](), "type not in FuncTs"]()

        @parameter
        for i in range(len(VariadicList(Self.Ts))):
            if _type_is_eq[Self.Ts[i], T]():
                return i
        return -1

    @staticmethod
    fn largest_size() -> Int:
        var largest = 0

        @parameter
        for i in range(len(VariadicList(Self.Ts))):
            if sizeof[Self.Ts[i]]() > largest:
                largest = sizeof[Self.Ts[i]]()
        return largest

    @implicit
    fn __init__[T: Callable](out self, owned value: T):
        constrained[Self.supports[T](), "type not in FuncTs"]()
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self))
        self._type_id = Self.type_id_of[T]()
        var ptr = UnsafePointer(to=self._data).bitcast[T]()
        ptr.init_pointee_move(value^)

    fn __del__(owned self):
        @parameter
        for i in range(len(VariadicList(Self.Ts))):
            if self._type_id == i:
                UnsafePointer(to=self._data).bitcast[
                    Self.Ts[i]
                ]().destroy_pointee()
                return

    fn __getitem__[T: Callable](self) -> ref [self._data] T:
        constrained[Self.supports[T](), "type not in FuncTs"]()
        if self._type_id != Self.type_id_of[T]():
            abort("Invalid type access")
        return UnsafePointer(to=self._data).bitcast[T]()[]
