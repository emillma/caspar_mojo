# from caspar import funcs
# from caspar.graph import Graph
# from caspar.graph_core import GraphCore
# from caspar.val import Val, Call, CasparElement
# from caspar.funcs import AnyFunc
# from collections import BitSet

# # from caspar.storage import ValStorage
# from sys import sizeof, alignof
# from memory import UnsafePointer

# # from caspar.val import Val, GraphRef
# from caspar.sysconfig import SymConfigDefault, SymConfig

# from caspar.collections import CallSet
# from sys.intrinsics import _type_is_eq


# trait Storable(Defaultable):
#     alias size: Int
#     alias ElemT: CasparElement

#     fn __getitem__(self, idx: Int) -> Self.ElemT:
#         ...

#     fn __setitem__(mut self, idx: Int, owned value: Self.ElemT):
#         ...


# struct SymbolStorage[
#     size_: Int,
#     config: SymConfig,
#     origin: ImmutableOrigin,
# ](Storable):
#     alias size = size_
#     alias ElemT = Val[AnyFunc, config, origin]

#     var data: InlineArray[Self.ElemT, Self.size]
#     var valid: BitSet[Self.size]

#     fn __init__(out self: Self):
#         self.data = InlineArray[Self.ElemT, Self.size](uninitialized=True)
#         self.valid = BitSet[Self.size]()

#     fn __getitem__(self, idx: Int) -> Self.ElemT:
#         debug_assert(self.valid.test(idx), "Index not valid")
#         return self.data[idx]

#     fn __setitem__(mut self, idx: Int, owned value: Self.ElemT):
#         debug_assert(not self.valid.test(idx), "Index not valid")
#         self.valid.set(idx)
#         self.data.unsafe_ptr().offset(idx).init_pointee_move(value^)


# trait Accessor:
#     alias StorableT: Storable


# struct UniqueAccessor[S: Storable](Accessor):
#     alias StorableT = S
#     var data: UnsafePointer[S]

#     @staticmethod
#     fn symbolic[
#         origin: ImmutableOrigin
#     ](out self: S, name: String, ref [origin]graph: Graph):
#         self = S()
#         for i in range(S.size):
#             self[i] = graph.add_call(funcs.ReadValue[1](name))[0]
