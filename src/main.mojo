from caspar.sys import System
from memory import ArcPointer, UnsafePointer
from compile.compile import compile_info
from sys import alignof, sizeof

var data = List[Int]()


fn foo[T: AnyType, val: T]() -> T:
    return val


alias bar = __type_of(foo)


fn main():
    # var data = List[Int](capacity=1)
    # data.append(1)
    # var ptr = Pointer(to=data[0])
    # for i in range(10):
    #     data.append(i)
    # print(data[0])
    # ptr[] += 8
    # print(ptr[])
    # print(data[0])
    var sys = System()
    var a = sys.symbol("a")
    print(a)
    # print(a)
    print("System created")
