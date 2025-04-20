# from compile.compile import compile_info

from caspar.sys import System, ExprRef
from memory import UnsafePointer
from utils import Variant


trait Callable:
    alias n_outs: Int
    alias n_args: Int

    @staticmethod
    fn get_repr(args: List[String], data: DataT) -> String:
        ...


# struct StoreFloat(Callable):
#     alias n_args = 0
#     alias n_outs = 1
#     var data: Float64

#     @staticmethod
#     fn get_repr(self: Call, args: List[String]) -> String:
#         return args[0] + " + " + args[1]


struct Symbol(Callable):
    alias n_args = 0
    alias n_outs = 1
    var name: String

    @staticmethod
    fn get_repr(args: List[String], data: DataT) -> String:
        return data[String]


struct Add(Callable):
    alias n_args = 2
    alias n_outs = 1

    @staticmethod
    fn get_repr(args: List[String], data: DataT) -> String:
        return args[0] + " + " + args[1]


alias DataT = Variant[Int, String]


@value
struct Call:
    var args: List[String]
    var data: DataT
    var get_repr: fn (List[String], DataT) -> String

    @staticmethod
    fn to[
        funcT: Callable
    ](
        out self: Self,
        owned args: List[String],
        owned data: DataT = DataT(unsafe_uninitialized=()),
    ):
        debug_assert(
            funcT.n_args == len(args),
            "Function {} expects {} arguments, but got {}",
        )
        self = Self(args^, data, funcT.get_repr)

    fn __str__(self) -> String:
        return self.get_repr(self.args, self.data)


fn main():
    print("Hello, Mojo!")

    fn foo() -> String:
        var a = Call.to[Add](List[String]("a", "b"))
        return String(a)

    alias foo_ = foo()
    print(foo_)
    # print(b)
    var sys = System()
    var x = sys.symbol("x")
    print(Int(UnsafePointer(to=x)))
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
