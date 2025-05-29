from hashlib._hasher import _HashableWithHasher, _Hasher, default_hasher


fn hash[*Ts: _HashableWithHasher](*values: *Ts) -> UInt64:
    """Compute the hash of multiple values using a specified hasher.

    Args:
        values: Values to be hashed.

    Returns:
        The computed hash value.
    """
    var hasher = default_hasher()

    @parameter
    for i in range(len(VariadicList(Ts))):
        hasher.update(values[i])
    return hasher^.finish()
