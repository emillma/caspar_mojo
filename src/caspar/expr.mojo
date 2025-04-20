from .system import System


@value
struct ExprData:
    var call_id: Int
    var out_idx: Int
    var use_ids: List[Int]


@value
@register_passable("trivial")
struct Expr[origin: MutableOrigin]:
    var sys: Pointer[System, origin]
    var id: Int

    fn add_use(mut self, use_id: Int):
        """Adds a use ID to the expression."""
        self.sys[]._exprs[self.id].use_ids.append(use_id)

    fn write_to[T: Writable](self, mut writer: T):
        """Writes the expression to the writer."""
