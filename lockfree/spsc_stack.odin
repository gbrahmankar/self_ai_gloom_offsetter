package lockfree

import "core:fmt"
import "base:intrinsics"
import "core:thread"
import "core:time"

STACK_MAX_SIZE :: 5

Stack_Node :: struct {
    value: u64,
    next: ^Stack_Node
}

Stack :: struct {
    top: ^Stack_Node,
    size: u64
}

perpetual_producer :: proc(all_stack_nodes: []Stack_Node, stack: ^Stack) {
}

spsc_stack :: proc() {
    all_stack_nodes := make([]Stack_Node, STACK_MAX_SIZE, context.temp_allocator)
    stack := make(Stack, 1, context.temp_allocator)
}