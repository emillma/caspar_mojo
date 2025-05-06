from memory import UnsafePointer


fn multihash[*Ts: Hashable](*args: *Ts) -> UInt:
    var ret: UInt = args[0].__hash__()

    @parameter
    for i in range(1, len(VariadicList(Ts))):
        ret += args[i].__hash__() * 33


fn origin_cast[
    mut: Bool, T: AnyType, //, origin: Origin[mut], origin_old: Origin[mut]
](ref [origin_old]thing: T) -> ref [origin] T:
    """Should only be used to mount an origin, e.g. struct.field -> struct."""
    return UnsafePointer(to=thing).origin_cast[origin=origin]()[]
