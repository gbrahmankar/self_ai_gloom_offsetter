package lockfree

import "core:fmt"
import "base:intrinsics"
import "core:thread"
import "core:time"

STACK_MAX_SIZE :: 5

Stack_Node :: struct {
    value: u64,
    in_use: bool,

    next: ^Stack_Node
}

Stack :: struct {
    top: ^Stack_Node,
    size: u64
}

available_node_index: u64

/*
perpetual_pusher ::
a) pluck a node off the array ::
    a) read the currently_available_node_index from the memory.
    b) mark the node as "under_use".
    c) increment the currently_available_node_index.
b) push it on the stack ::
    a) read stack top
    b) make stack_node's next point to where the top point's
    c) make stack's top point to the new stack_node
*/

perpetual_pusher :: proc(all_stack_nodes: []Stack_Node, stack: ^Stack) {
    for true {
        if available_node_index + 1 > STACK_MAX_SIZE {
            continue
        }

        stack_node := &all_stack_nodes[available_node_index]
        stack_node.in_use = true
        available_node_index += 1

        stack_node.next = stack.top
        stack.top = stack_node
    }
}

/*
perpetual_popper ::
a) pluck a node off the array ::
    a) read the currently_available_node_index from the memory.
    b) mark the node as "under_use".
    c) increment the currently_available_node_index.
b) push it on the stack ::
    a) read stack top
    b) make stack_node's next point to where the top point's
    c) make stack's top point to the new stack_node
*/

perpetual_popper :: proc(all_stack_nodes: []Stack_Node, stack: ^Stack) {
    for true {
        if available_node_index > 0 {
            continue
        }

        temp_node := stack.top
        temp_node.in_use = false
        temp_node.next = nil

        stack.top = stack.top.next

        available_node_index -= 1
    }
}

spsc_stack :: proc() {
    all_stack_nodes := make([]Stack_Node, STACK_MAX_SIZE, context.temp_allocator)
    stack := new(Stack, context.temp_allocator)

    perpetual_pusher(all_stack_nodes, stack)
    perpetual_popper(all_stack_nodes, stack)
}