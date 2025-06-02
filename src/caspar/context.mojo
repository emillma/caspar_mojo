from .graph_core import GraphCore, CallIdx, ValIdx
from .collections import RegIdx
from caspar.sysconfig import SymConfig
from compile.reflection import get_type_name


trait Context:
    ...


struct CpuContext:
    ...


struct KernelData[config: SymConfig]:
    var graph: GraphCore[config]
    var order: List[List[CallIdx]]
    var regmap: Dict[ValIdx, RegIdx]

    fn __init__(
        out self,
        owned graph: GraphCore[config],
        owned order: List[List[CallIdx]],
        owned regmap: Dict[ValIdx, RegIdx],
    ):
        self.graph = graph^
        self.order = order^
        self.regmap = regmap^


fn make_kernel[config: SymConfig, //, data: KernelData[config]]() -> fn ():
    fn inner():
        @parameter
        for i in range(len(data.order)):

            @parameter
            for j in range(len(data.order[i])):
                alias callidx = data.order[i][j]
                alias name = config.funcs.Ts[Int(callidx.type)].info.fname
                print("CallIdx:", name)

    return inner
