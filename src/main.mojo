# from compile.compile import compile_info

from memory import UnsafePointer
from utils import Variant
from caspar.system import System, Expr, Symbol


struct Foo:
    var data: Int

    fn __init__(out self, data: Int):
        print("Foo.__init__")
        self.data = data

    fn __copyinit__(out self, other: Foo):
        print("Foo.__copyinit__")
        self.data = other.data

    fn __moveinit__(out self, owned other: Foo):
        print("Foo.__moveinit__")
        self.data = other.data


fn main():
    # print(b)

    var foo = Foo(1)
    var list = List[Foo](foo^)
    # list[0] = foo
    print(list[0].data)
    var sys = System()
    var x = sys.call[Symbol]()
    print(UnsafePointer(to=x.sys[]))
    # print(Int(UnsafePointer(to=x)))
    # fn inner() -> System:
    #     # var pose_a = Pose3(sys, 'pose_a')
    #     # var pose_b = Pose3(sys, 'pose_b')
    #     # var pose_c = pose_a.retract(pose_b)
    #     # sys.inputs
    #     return sys

    # var a = foo()
    # var a = get_linkage_name[Symbol]()
    # a = A(UnsafePointer(to=A.foo))
    # var name: String = "123"
    # var sym = Symbol(name)

    # print(x.__str__())

    # print(sizeof[A]())
    # var foo = sys.calls
