from .sysconfig import SymConfig, Config
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


@explicit_destroy
struct LockToken:
    fn __init__(out self, *, create: Bool):
        pass


struct Graph[sym: SymConfig](Movable):
    """Exposed interface for the graph."""

    alias LockToken = Int

    var _core: GraphCore[sym]
    var _locked: Bool

    fn __init__(out self):
        self._core = GraphCore[sym]()
        self._locked = 0

    fn _mut_core(
        self, token: LockToken
    ) -> ref [MutableOrigin.cast_from[__origin_of(self._core)].result] GraphCore[sym]:
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
        ref [origin]self,
        owned func: FT,
        owned *args: Val[Config[sym, origin]],
        out ret: Call[Config[sym, origin]],
    ):
        var token = self._aquire()
        var arglist = IndexList[ValIdx](capacity=len(args))

        for i in range(len(args)):
            arglist.append(args[i].idx)

        ret = Call[Config[sym, origin]](
            Pointer(to=self),
            self._mut_core(token).callmem_add[FT](func, arglist^),
        )
        self._release(token^)

    fn __is__[T: AnyType](self, other: T) -> Bool:
        @parameter
        if not _type_is_eq[Self, T]():
            return False
        return UnsafePointer(to=self) == UnsafePointer(to=rebind[Self](other))

    fn take_core(owned self, out core: GraphCore[sym]):
        """Take ownership of the core, leaving the graph empty."""
        var token = self._aquire()
        core = self._core^
        __disable_del token
        __disable_del self

    fn __is__(self, other: Graph) -> Bool:
        """Check if two graphs are the same."""

        @parameter
        if _type_is_eq[Self, __type_of(other)]():
            return UnsafePointer(to=self) == UnsafePointer(to=rebind[Self](other))
        return False

    fn __isnot__(self, other: Graph) -> Bool:
        """Check if two graphs are not the same."""
        return not self is other
