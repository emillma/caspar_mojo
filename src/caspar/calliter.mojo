from caspar.graph import Graph
from caspar.sysconfig import SymConfig
from caspar.collections import CallIdx
from caspar.val import Val, Call
from collections import Set


struct CallChildIter[config: SymConfig, origin: ImmutableOrigin](Copyable, Movable):
    var graph: Pointer[Graph[config], origin]
    var tracked: Set[CallIdx]
    var stack: List[CallIdx]

    fn __init__(
        out self,
        start: Call[config, origin],
        tracked: Optional[Set[CallIdx]] = None,
    ):
        self.graph = start.graph
        self.tracked = tracked.value() if tracked else Set[CallIdx]()
        self.stack = [start.idx]
        self.tracked.add(start.idx)

    fn __iter__(self) -> Self:
        return self

    fn __next__(mut self, out call: Call[config, origin]):
        while True:
            var missing_args = False
            for arg in self.graph[]._core[self.stack[-1]].args:
                var parent_call = self.graph[]._core[arg].call
                if missing_args := parent_call not in self.tracked:
                    self.stack.append(parent_call)
                    self.tracked.add(parent_call)
            if not missing_args:
                return Call(self.graph, self.stack.pop())

    @always_inline
    fn __has_next__(self) -> Bool:
        return len(self.stack) > 0
