from memory import Pointer, Span, UnsafePointer, memcpy


@explicit_destroy
struct OwnedList[T: AnyType]:
    var data: Int

    fn __init__(out self):
        self.data = 0

    fn __copyinit__(out self, other: OwnedList[T]):
        self.data = other.data

    fn __moveinit__(out self, owned other: OwnedList[T]):
        self.data = other.data

    fn destroy(owned self):
        __disable_del self
