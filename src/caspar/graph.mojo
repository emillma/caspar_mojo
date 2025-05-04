from .storage import Storable


trait Accessor(Movable & Copyable):
    ...


@value
struct ReadSequential[T: Storable](Accessor):
    var storage: T

    fn __init__(out self, storage: T):
        self.storage = storage


@value
struct WriteSequential[T: Storable](Accessor):
    var storage: T

    fn __init__(out self, storage: T):
        self.storage = storage


struct Graph[*Ts: Accessor]:
    # var accessors: Tuple[*Ts]
    alias name = "123"
    alias _mlir_type = __mlir_type[
        `!kgen.pack<:!kgen.variadic<`,
        Accessor,
        `> `,
        Ts,
        `>`,
    ]

    var storage: Self._mlir_type

    fn __init__(out self, *accessors: *Ts):
        __mlir_op.`lit.ownership.mark_initialized`(__get_mvalue_as_litref(self.storage))
