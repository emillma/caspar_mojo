from compile.reflection import get_type_name


trait ArgType:
    alias arg_type_key: StaticString
    alias key_: String
    alias size_: Int


struct MemArg[name: StaticString = "", size: Int = -1](ArgType):
    alias arg_type_key = "mem"
    alias key_ = String("_").join(get_type_name[Self](), name, String(size))
    alias size_ = size

    @staticmethod
    fn get_key(name: String, size: Int) -> String:
        return String("_").join("MemArg", name, String(size))


struct PtrArg[name: StaticString = "", size: Int = -1](ArgType):
    alias arg_type_key = "ptr"
    alias key_ = String("_").join(get_type_name[Self](), name, String(size))
    alias size_ = size

    @staticmethod
    fn get_key(name: String, size: Int) -> String:
        return String("_").join("PtrArg", name, String(size))
