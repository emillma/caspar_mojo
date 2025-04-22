from caspar.functions import CallableVariantDefault, Symbol, Add

alias FuncT = CallableVariantDefault


fn main():
    # var foo = List[Int]()
    # foo.capacity = 10
    # for i in range(10):
    #     foo.append(i)  # SEGFAULT

    var a = FuncT(Symbol("a"))
    var b = FuncT(Add())
    print(a.repr())
    print(b.repr(List[String]("a", "b")))
