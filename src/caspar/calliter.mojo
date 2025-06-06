from caspar.graph import Graph
from caspar.sysconfig import SymConfig
from caspar.collections import CallIdx
from caspar.val import Val, Call
from collections import Set


struct CallChildIter[config: SymConfig, origin: ImmutableOrigin](Movable, Copyable):
    var graph: Pointer[Graph[config], origin]
    var tracked: Set[CallIdx]
    var stack: List[CallIdx]

    fn __init__(out self, start: Call[config, origin]):
        self.graph = start.graph
        self.stack = [start.idx]
        self.tracked = {start.idx}

    fn __init__(out self, starts: List[Call[config, origin]]):
        self.graph = starts[0].graph
        self.tracked = {}
        self.stack = []
        for ref start in starts:
            if start.idx not in self.tracked:
                self.stack.append(start.idx)
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
