from .func_set import FuncSet, FuncT


@value
struct Store(FuncT):
    alias n_args = 0
    alias n_outs = 1


@value
struct Symbol(FuncT):
    alias n_args = 0
    alias n_outs = 1
    var name: String


@value
struct Add(FuncT):
    alias n_args = 2
    alias n_outs = 1


alias FuncVariant = FuncSet[Store, Symbol, Add]
