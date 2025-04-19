# from compile.compile import compile_info

from caspar.sys import System


fn foo() -> AnyType:
    return Int


fn main():
    print("Hello, Mojo!")
    # bar[*foo[Int, Float64]()]()

    var sys = System()
    var x = sys.symbol("x")

    # var a = foo()
    # var a = get_linkage_name[Symbol]()
    # a = A(UnsafePointer(to=A.foo))
    # var name: String = "123"
    # var sym = Symbol(name)

    # print(x.__str__())

    # print(sizeof[A]())
    print("System created")
    var foo = sys.calls
