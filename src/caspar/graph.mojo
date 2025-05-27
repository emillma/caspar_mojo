from .sysconfig import SymConfig
from memory import UnsafePointer
from . import funcs
from .funcs import Callable, AnyFunc, StoreOne, StoreZero, StoreFloat
from .val import Call, Val, CasparElement
from .graph_utils import CallIdx, ValIdx, OutIdx, StackList, CallInstanceIdx
from .graph_core import GraphCore, CallMem, ValMem
from sys.intrinsics import _type_is_eq
from sys import sizeof, alignof
from utils.lock import BlockingSpinLock


@fieldwise_init
struct MutKey:
    ...


@fieldwise_init
struct MutLock:
    fn __enter__(mut self) -> MutKey:
        return MutKey()

    fn __exit__(mut self):
        return


struct Graph[config: SymConfig]:
    alias LockToken = Int
    var _core: GraphCore[config]

    fn __init__(out self):
        self._core = GraphCore[config]()

    fn _mut_core(
        self, token: MutKey
    ) -> ref [MutableOrigin.cast_from[__origin_of(self._core)].result] GraphCore[
        config
    ]:
        return UnsafePointer(to=self._core).origin_cast[
            True, MutableOrigin.cast_from[__origin_of(self._core)].result
        ]()[]

    fn get_callmem[
        FT: Callable, origin: ImmutableOrigin
    ](ref [origin]self, call: Call[FT, config, origin]) -> ref [
        self._core.callmem_any[FT=FT](call.idx)
    ] CallMem[FT, config]:
        return self._core.callmem_any[FT=FT](call.idx)

    fn get_valmem[
        FT: Callable, origin: ImmutableOrigin
    ](ref [origin]self, val: Val[FT, config, origin]) -> ref [
        self._core.valmem(val.idx)
    ] ValMem[config]:
        return self._core.valmem(val.idx)

    fn add_call[
        FT: Callable, *ArgTs: CasparElement, origin: ImmutableOrigin
    ](
        ref [origin]self,
        owned func: FT,
        owned *args: *ArgTs,
    ) -> Call[
        FT, config, origin
    ]:
        var arglist = StackList[ValIdx](capacity=len(args))

        @parameter
        for i in range(len(VariadicList(ArgTs))):
            arglist.append(args[i].as_val(self).idx)
        return Call[FT, config, origin](
            Pointer(to=self),
            self._mut_core(MutKey()).callmem_add[FT](func, arglist),
        )
