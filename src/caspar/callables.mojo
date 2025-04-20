from utils import Variant


alias DataVariant = Variant[Float64, String, Int, Bool, NoneType._mlir_type]


trait Callable:
    alias n_outs: Int
    alias n_args: Int
    alias DataT: CollectionElement

    @staticmethod
    fn get_repr(args: List[String], data: DataVariant) -> String:
        ...


struct StoreFloat(Callable):
    alias n_args = 0
    alias n_outs = 1
    alias DataT = NoneType._mlir_type

    @staticmethod
    fn get_repr(args: List[String], data: DataVariant) -> String:
        return String(data[Float64])


struct Symbol(Callable):
    alias n_args = 0
    alias n_outs = 1
    alias DataT = String

    @staticmethod
    fn get_repr(args: List[String], data: DataVariant) -> String:
        return data[String]


struct Add(Callable):
    alias n_args = 2
    alias n_outs = 1
    alias DataT = NoneType._mlir_type

    @staticmethod
    fn get_repr(args: List[String], data: DataVariant) -> String:
        return data[String]
