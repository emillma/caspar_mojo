from caspar.config import FuncVariant
from memory import UnsafePointer
from . import funcs
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat
from .val import Call, Val
from .collections import CallIdx, ValIdx, OutIdx, IndexList
from .graph_core import GraphCore, CallMem, ValMem
from sys.intrinsics import _type_is_eq
from sys import sizeof, alignof
from utils.lock import BlockingSpinLock
from os.atomic import Atomic
from caspar.config import AccessVariant
from caspar.accessors import Accessor


@explicit_destroy
struct LockToken:
    fn __init__(out self, *, create: Bool):
        pass


trait GraphT(Movable):
    ...


struct Graph(GraphT):
    """Exposed interface for the graph."""

    alias LockToken = Int
    var _core: GraphCore
    var _locked: Bool

    fn __init__(out self):
        self._core = GraphCore()
        self._locked = 0

    fn _mut_core(
        self, token: LockToken
    ) -> ref [MutableOrigin.cast_from[__origin_of(self._core)].result] GraphCore:
        return UnsafePointer(to=self._core).origin_cast[
            True, MutableOrigin.cast_from[__origin_of(self._core)].result
        ]()[]

    fn _aquire(self) -> LockToken:
        debug_assert(self._locked == 0, "Graph is already locked")
        UnsafePointer(to=self._locked).origin_cast[
            True, MutableOrigin.cast_from[__origin_of(self._locked)].result
        ]()[] = 1
        return LockToken(create=True)

    fn _release(self, owned token: LockToken):
        UnsafePointer(to=self._locked).origin_cast[
            True, MutableOrigin.cast_from[__origin_of(self._locked)].result
        ]()[] = 0
        __disable_del token

    fn add_call[
        FT: Callable, origin: ImmutableOrigin
    ](
        ref [origin]self: Self,
        owned func: FT,
        owned *args: Val[origin],
        out ret: Call[origin],
    ):
        var token = self._aquire()
        var arglist = IndexList[ValIdx](capacity=len(args))

        for i in range(len(args)):
            arglist.append(args[i].idx)

        ret = Call[origin](
            Pointer(to=self),
            self._mut_core(token).callmem_add[FT](func, arglist^),
        )
        self._release(token^)

    fn __is__[T: AnyType](self, other: T) -> Bool:
        @parameter
        if not _type_is_eq[Self, T]():
            return False
        return UnsafePointer(to=self) == UnsafePointer(to=rebind[Self](other))

    fn take_core(owned self, out core: GraphCore):
        """Take ownership of the core, leaving the graph empty."""
        var token = self._aquire()
        core = self._core^
        __disable_del token
        __disable_del self

    fn same_as(self, other: Graph) -> Bool:
        """Check if two graphs are the same."""

        @parameter
        if _type_is_eq[Self, __type_of(other)]():
            return UnsafePointer(to=self) == UnsafePointer(to=rebind[Self](other))
        return False

    fn make_kernel(self, owned *args: AccessVariant):
        """Create a kernel call with the given arguments."""
        var new_graph = Graph()
        var val_map = Dict[ValIdx, ValIdx]()
        var call_map = Dict[CallIdx, CallIdx]()

        for arg in args:
            if arg.is_read:
                var val_list = IndexList[ValIdx]()

                @parameter
                fn inner[T: Accessor](val: T):
                    val_list = val.read_into(new_graph)

                arg.do[inner]()
                print(val_list)
