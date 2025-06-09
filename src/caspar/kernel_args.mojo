from compile.reflection import get_type_name
from memory import UnsafePointer


@register_passable
trait Argument(Copyable, Movable, Writable):
    alias KEY: StaticString
    alias elem_size_: Int


# @register_passable
# struct MemArg[elem_size: Int](Argument):
#     alias KEY: StaticString = String("_").join("mem", String(elem_size))
#     alias elem_size_ = elem_size


@register_passable
struct PtrArg[elem_size: Int](Argument):
    alias KEY: StaticString = String("_").join("ptr", String(elem_size))
    alias elem_size_ = elem_size
    var ptr: UnsafePointer[Float32]
    var size: Int

    fn __init__(out self, data: InlineArray[Float32, elem_size]):
        self.ptr = data.unsafe_ptr()
        self.size = data.size

    fn __len__(self) -> Int:
        return self.size

    fn write_to[W: Writer](self, mut writer: W):
        writer.write("PtrArg:", String(self.ptr), String(self.KEY))
