from .sysconfig import SymConfig
from memory import UnsafePointer
from . import funcs
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat
from .val import Call, Val, CasparElement
from .collections import CallIdx, ValIdx, OutIdx, IndexList, CallInstanceIdx
from .graph_core import GraphCore, CallMem, ValMem
from sys.intrinsics import _type_is_eq
from sys import sizeof, alignof
from utils.lock import BlockingSpinLock
from os.atomic import Atomic


@explicit_destroy
struct LockToken:
    fn __init__(out self, *, create: Bool):
        pass


struct Graph[config: SymConfig](Movable):
    """Exposed interface for the graph."""

    alias LockToken = Int
    var _core: GraphCore[config]
    var _locked: Bool

    fn __init__(out self):
        self._core = GraphCore[config]()
        self._locked = 0

    fn _mut_core(
        self, token: LockToken
    ) -> ref [MutableOrigin.cast_from[__origin_of(self._core)].result] GraphCore[
        config
    ]:
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

    fn get_callmem[
        origin: ImmutableOrigin
    ](ref [origin]self, call: Call[config, origin]) -> ref [
        self._core[call.idx]
    ] CallMem[config]:
        return self._core[call.idx]

    fn get_valmem[
        origin: ImmutableOrigin
    ](ref [origin]self, val: Val[config, origin]) -> ref [self._core[val.idx]] ValMem[
        config
    ]:
        return self._core[val.idx]

    fn add_call[
        FT: Callable, *ArgTs: CasparElement, origin: ImmutableOrigin
    ](
        ref [origin]self,
        owned func: FT,
        owned *args: *ArgTs,
        out ret: Call[config, origin],
    ):
        var token = self._aquire()
        var arglist = IndexList[ValIdx](capacity=len(args))

        @parameter
        for i in range(len(VariadicList(ArgTs))):
            arglist.append(args[i].as_val(self, token).idx)

        ret = Call[config, origin](
            Pointer(to=self),
            self._mut_core(token).callmem_add[FT](func, arglist^),
        )
        self._release(token^)

    fn __is__[T: AnyType](self, other: T) -> Bool:
        @parameter
        if not _type_is_eq[Self, T]():
            return False
        return UnsafePointer(to=self) == UnsafePointer(to=rebind[Self](other))

    fn take_core(owned self, out core: GraphCore[config]):
        """Take ownership of the core, leaving the graph empty."""
        var token = self._aquire()
        core = self._core^
        __disable_del token
        __disable_del self
