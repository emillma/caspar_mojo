# from caspar.compile import Kernel, Arg
# from caspar import accessors
# from caspar.graph import Graph
# from caspar.sysconfig import DefaultSymConfig, SymConfig
# from caspar.storage import Vector, Storable
# from caspar import funcs
from sys.intrinsics import _type_is_eq


# fn foo():
#     var graph = Graph[DefaultSymConfig]()
#     var x = Vector[4]("x", graph)
#     var y = Vector[4]("y", graph)
#     var z = x + y
#     var bar = graph.make_kernel(
#         accessors.ReadUnique(x),
#         accessors.ReadUnique(y),
#         # accessors.WriteUnique(z),
#     )


# ret = Kernel((graph.mark[ReadUnique](x).mark[ReadUnique](y).mark[WriteUnique](z)))
alias TraitType = AnyTrivialRegType


#     alias count = len(VariadicList(Ts))


#     @staticmethod
#     fn index_of[T: traitT]() -> Int:
#         @parameter
#         for i in range(len(VariadicList(Ts))):
#             if __mlir_attr[
#                 `#kgen.param.expr<eq,`,
#                 `#kgen.type<`,
#                 +T,
#                 `> : !kgen.type`,
#                 `,`,
#                 `#kgen.type<`,
#                 +Ts[i],
#                 `> : !kgen.type`,
#                 `> : i1`,
#             ]:
#                 return i
#         return -1
struct Collection[Trait: TraitType, *Ts: Trait]:
    alias count = len(VariadicList(Ts))


alias foo: __mlir_type[`!kgen.variadic<`, Writable, `>`] = Collection[
    Writable, Int, Float32, String
].Ts


fn main():
    # print(len(VariadicList(DefaultSymConfig.func_types)))
    print(len(VariadicList[Writable](foo)))
