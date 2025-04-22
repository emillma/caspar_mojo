struct Shared:
    var x: Bool

    fn __init__(out self, x: Bool):
        self.x = x

    @always_inline("nodebug")
    fn __init__(out self, nms: NmStruct):
        self.x = True if (nms.x == 77) else False


struct NmStruct:
    var x: Int

    @always_inline("nodebug")
    fn __add__(self, rhs: Self) -> Self:
        return NmStruct(self.x + rhs.x)


alias still_nm_struct = NmStruct(1) + NmStruct(2)
# When materializing to a run-time variable, it is automatically converted,
# even without a type annotation.
var converted_to_has_bool = still_nm_struct
