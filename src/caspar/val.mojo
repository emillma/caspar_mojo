from .graph import Graph, CallMem, ValMem, LockToken
from .collections import CallIdx, ValIdx, OutIdx, IndexList
from caspar.config import FuncVariant
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat

from sys.intrinsics import _type_is_eq


@value
@register_passable
struct Call[origin: ImmutableOrigin](KeyElement, Writable):
    var graph: Pointer[Graph, origin]
    var idx: CallIdx

    fn __getitem__(
        self,
    ) -> ref [self.graph[]._core[self.idx]] CallMem:
        return self.graph[]._core[self.idx]

    fn arg(self, idx: ValIdx) -> Val[origin]:
        return Val[origin](self.graph, self[].args[idx])

    fn func(self) -> ref [self[].func] __type_of(self[].func):
        return self[].func

    fn __getitem__(self, idx: Int) -> Val[origin]:
        return self.out(idx)

    fn out(self, idx: Int) -> Val[origin]:
        return Val[origin](self.graph, self[].outs[idx])

    fn write_to[W: Writer](self, mut writer: W):
        @parameter
        fn inner[T: Callable](val: T):
            val.write_call(self, writer)

        self.func().do[inner]()

    fn __eq__(self, other: Self) -> Bool:
        return self.graph == other.graph and self.idx == other.idx

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return hash(self[])


@value
@register_passable
struct Val[origin: ImmutableOrigin](Writable):
    var graph: Pointer[Graph, origin]
    var idx: ValIdx

    fn __getitem__(self) -> ref [self.graph[]._core[self.idx]] ValMem:
        return self.graph[]._core[self.idx]

    fn call(self) -> Call[origin]:
        return Call[origin](self.graph, self[].call)

    fn write_to[W: Writer](self, mut writer: W):
        writer.write(self.call())
        if self[].out_idx != 0:
            writer.write("[", Int(self[].out_idx), "]")

    fn __eq__(self, other: Self) -> Bool:
        return self.graph == other.graph and self.idx == other.idx

    fn __ne__(self, other: Self) -> Bool:
        return not self == other

    fn __hash__(self) -> UInt:
        return hash(self[])
