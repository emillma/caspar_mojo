from .system import System
from .call import CallRef, CallData


@value
struct ExprData:
    var call_id: Int
    var out_idx: Int
    var use_ids: List[Int]


@value
@register_passable("trivial")
struct ExprRef[origin: MutableOrigin]:
    var sys: Pointer[System, origin]
    var id: Int

    fn add_use(mut self, use_id: Int):
        """Adds a use ID to the expression."""
        self.sys[]._exprs[self.id].use_ids.append(use_id)

    fn calldata(self) -> ref [origin] CallData:
        """Returns the call reference."""
        return self.sys[]._calls[self.sys[][self].call_id]

    fn call(self) -> CallRef[origin]:
        """Returns the call reference."""
        return CallRef(self.sys, self.sys[][self].call_id)

    fn __str__(self) -> String:
        """Writes the expression to the writer."""
        # var foo = len(self.callmem().arg_ids)
        # print(foo)
        return self.sys[][self.call()].get_repr(
            List[String]("hello", "world"),
            self.sys[][self.call()].data,
        )
