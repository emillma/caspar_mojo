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

    fn mut(
        self, token: MutKey
    ) -> ref [MutableOrigin.cast_from[__origin_of(self)].result] Self:
        return UnsafePointer(to=self).origin_cast[
            True, MutableOrigin.cast_from[__origin_of(self)].result
        ]()[]

    # fn get_call[
    #     FT: Callable = AnyFunc
    # ](self, idx: CallIdx) -> Call[AnyFunc, config, __origin_of(self)]:
    #     debug_assert(
    #         config.funcs.func_to_idx[FT]() == Int(idx.type), "Type mismatch in get_call"
    #     )
    #     return Call[FT](Pointer[origin = __origin_of(self)](to=self), idx)

    # fn get_val[
    #     FT: Callable
    # ](self, idx: ValIdx) -> Val[FT, config, __origin_of(self)]:
    #     debug_assert(
    #         config.funcs.func_to_idx[FT]() == Int(self.vals[idx].call_idx.type),
    #         "Type mismatch in get_val",
    #     )
    #     return Val[FT](Pointer(to=self), idx)

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

    # fn add_call[
    #     FT: Callable, *ArgTs: CasparElement, origin: ImmutableOrigin
    # ](
    #     ref [origin]self,
    #     owned func: FT,
    #     owned *args: *ArgTs,
    # ) -> Call[
    #     FT, config, origin
    # ]:
    #     var arglist = StackList[ValIdx](capacity=len(args))

    #     @parameter
    #     for i in range(len(VariadicList(ArgTs))):
    #         arglist.append(args[i].as_val(self).idx)

    #     var outlist = StackList[ValIdx](capacity=func.n_outs())

    #         for i in range(func.n_outs()):
    #             outlist.append(len(self.vals))
    #     with MutLock() as key:
    #         var call_idx = self.mut(key).calls.add_call[FT](
    #             CallMem[FT, config](arglist, outlist, func)
    #         )
    #         for i in range(func.n_outs()):
    #             self.mut(key).vals.append(ValMem[config](call_idx, i))
    #         return Call[FT, config, origin](Pointer(to=self), call_idx)
