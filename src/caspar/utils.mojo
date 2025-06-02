from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher


fn multihash[*Ts: Hashable](*values: *Ts) -> UInt:
    var ret = hash(values[0])

    @parameter
    for i in range(1, len(VariadicList(Ts))):
        ret = ret * 33 + hash(values[i])
    return ret
