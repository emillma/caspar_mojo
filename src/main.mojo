from caspar.functions import Symbol, Add
from caspar.expr import Expr, Call
from caspar.sysconfig import SymConfigDefault, SymConfig, RunTimeDefault
from sys import sizeof
from caspar.storage import Storage, Vec
from caspar.graph import Graph, ReadSequential, WriteSequential
from random import seed
from hashlib.hash import _HASH_SECRET
from memory import UnsafePointer


fn foo() -> String:
    x = Call[SymConfigDefault](Symbol("x"))[0]
    y = Call[SymConfigDefault](Symbol("y"))[0]
    v1 = Vec[_, 2](x, y)
    v2 = Vec[_, 2](x, x)

    var graph = Graph(
        ReadSequential(v1),
        WriteSequential(v2),
    )

    return ""


fn main():
    print(foo())
