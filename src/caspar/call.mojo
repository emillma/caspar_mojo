from .callables import DataVariant
from .system import System


@value
struct CallData:
    var arg_ids: List[Int]
    var out_ids: List[Int]
    var data: DataVariant

    ### Func destcription
    var funcid: Int
    var ger_repr: fn (List[String], DataVariant) -> String

    fn __init__(
        out self,
        n_args: Int,
        n_outs: Int,
        data: DataVariant,
        func_id: Int,
        ger_repr: fn (List[String], DataVariant) -> String,
    ):
        self.arg_ids = List[Int](capacity=n_args)
        self.out_ids = List[Int](capacity=n_outs)
        self.data = data
        self.funcid = func_id
        self.ger_repr = ger_repr


@value
@register_passable("trivial")
struct Call[origin: MutableOrigin]:
    var sys: Pointer[System, origin]
    var id: Int
