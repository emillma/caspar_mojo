from .storage import Storable
from memory import UnsafePointer

from .utils import origin_cast


trait Accessor(Movable & Copyable):
    # alias storageT: Storable
    alias storageT: Storable

    fn __init__(out self, owned storage: Self.storageT):
        ...

    # fn target(ref self) -> ref [self] Self.storageT:
    #     ...


@value
struct ReadSequential[T: Storable](Accessor):
    alias storageT = T
    # var _storage: Self.storageT

    fn __init__(out self, owned storage: Self.storageT):
        ...
        # self._storage = storage

    # fn target(ref self) -> ref [self] Self.storageT:
    #     return origin_cast[__origin_of(self)](self._storage)


@value
struct WriteSequential[T: Storable](Accessor):
    alias storageT = T
    # var _storage: Self.storageT

    fn __init__(out self, owned storage: Self.storageT):
        ...
        # self._storage = storage

    # fn target(ref self) -> ref [self] Self.storageT:
    #     return origin_cast[__origin_of(self)](self._storage)


struct Graph[*Ts: Accessor]:
    # var accessors: Tuple[*Ts]
    alias name = "123"
    alias _mlir_type = __mlir_type[
        `!kgen.pack<:!kgen.variadic<`, Accessor, `> `, Ts, `>`
    ]
    alias num_accessors = len(VariadicList(Self.Ts))
    # var storage: Self._mlir_type

    @always_inline("nodebug")
    fn __init__(out self, *args: *Ts):
        """Construct the tuple.

        Args:
            args: Initial values.
        """
        ...
        # self = Self(storage=args^)

    # @always_inline("nodebug")
    # fn __init__(out self, *, owned storage: VariadicPack[_, _, Accessor, *Ts]):
    #     ...
    # __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self.storage))

    # @parameter
    # for i in range(Self.num_accessors):
    #     UnsafePointer(to=storage[i]).move_pointee_into(
    #         UnsafePointer(to=self.accesor[i]())
    #     )
    # __disable_del storage

    fn code(self) -> String:
        var out: String = ""

        # @parameter
        # for i in range(Self.num_accessors):
        #     var accessor = self.accesor[i]()
        #     var storage = accessor.target().to_storage()
        #     for j in range(len(storage)):
        #         print(storage[j])

        # for arg in self.storage[0].to_storage():
        return out

    # @always_inline("nodebug")
    # fn accesor[idx: Int](ref self) -> ref [self] Ts[idx.value]:
    #     var elt_kgen_ptr = __mlir_op.`kgen.pack.gep`[index = idx.value](
    #         UnsafePointer(to=self.storage).address
    #     )
    #     return UnsafePointer(elt_kgen_ptr)[]
