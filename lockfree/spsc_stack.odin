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

all_stack_nodes: []Stack_Node
stack: ^Stack
available_node_index: u64

/*
perpetual_pusher ::
a) pluck a node off the array ::
    a) read the currently_available_node_index from the memory.
    b) mark the node as "under_use".
    c) increment the currently_available_node_index.
b) push it on the stack ::
    a) read stack top
    b) make stack_node's next point to where the top points
    c) make stack's top point to the new stack_node
*/
perpetual_pusher :: proc() {
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
a) pop it off the stack ::
    a) copy the value of the stack top locally
    b) stack top's value to stack top next
b) put the popped node back in the array ::
    a) mark the node as not in use
    b) decrement the available_node_index counter
*/
perpetual_popper :: proc() {
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
    all_stack_nodes = make([]Stack_Node, STACK_MAX_SIZE, context.temp_allocator)
    stack = new(Stack, context.temp_allocator)

    pusher_thread_handle := thread.create_and_start(perpetual_pusher)
    popper_thread_handle := thread.create_and_start(perpetual_popper)

    thread.join(pusher_thread_handle)
    thread.join(popper_thread_handle)
}