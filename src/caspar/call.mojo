from .callables import DataVariant
from .system import System
from .expr import ExprRef


@value
struct CallData:
    var arg_ids: List[Int]
    var out_ids: List[Int]
    var data: DataVariant

    ### Func destcription
    var funcid: Int
    var get_repr: fn (List[String], DataVariant) -> String

    fn __init__(
        out self,
        n_args: Int,
        n_outs: Int,
        data: DataVariant,
        func_id: Int,
        get_repr: fn (List[String], DataVariant) -> String,
    ):
        self.arg_ids = List[Int](capacity=n_args)
        self.out_ids = List[Int](capacity=n_outs)
        self.data = data
        self.funcid = func_id
        self.get_repr = get_repr


@value
@register_passable("trivial")
struct CallRef[origin: MutableOrigin]:
    var sys: Pointer[System, origin]
    var id: Int

    fn __getitem__(self, idx: Int) -> ExprRef[origin]:
        return ExprRef(self.sys, self.sys[]._calls[self.id].out_ids[idx])
