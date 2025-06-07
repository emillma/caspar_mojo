from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher
from sys.intrinsics import _type_is_eq


fn hashupdate[T: Hashable](mut val: UInt, other: T):
    val = val * 33 + hash(other)


fn multihash[*Ts: Hashable](*values: *Ts, out ret: UInt):
    ret = hash(values[0])

    @parameter
    for i in range(1, len(VariadicList(Ts))):
        hashupdate(ret, values[i])


struct Foo[origin: Origin]:
    ...


fn same_origin[a: Origin, b: Origin]() -> Bool:
    return _type_is_eq[Foo[a], Foo[b]]()
