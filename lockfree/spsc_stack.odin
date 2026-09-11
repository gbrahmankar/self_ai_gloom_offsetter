package lockfree

import "core:fmt"
import "base:intrinsics"
import "core:thread"
import "core:time"

Stack_Node :: struct {
    value: u64,
    next: ^Stack_Node
}

Stack :: struct {
    top: ^Stack_Node,
    size: u64
}

stack: ^Stack

/*
perpetual_pusher ::
*/
perpetual_pusher :: proc() {
    for true {
        new_stack_node := new(Stack_Node, context.temp_allocator)

        for true {
            stack_top := intrinsics.atomic_load_explicit(&stack.top, .Relaxed)
            new_stack_node.next = stack_top

            _, success := intrinsics.atomic_compare_exchange_strong(&stack.top, stack_top, new_stack_node)
            if (success) {
                break
            }
        }
    }
}

/*
perpetual_popper ::
*/
perpetual_popper :: proc() {
    for true {
        for true {
            old_stack_top := intrinsics.atomic_load_explicit(&stack.top, .Relaxed)
            if old_stack_top == nil {
                continue
            }
            new_stack_top := old_stack_top.next

            _, success := intrinsics.atomic_compare_exchange_strong(&stack.top, old_stack_top, new_stack_top)
            if (success) {
                free(old_stack_top)
                break
            }
        }
    }
}

spsc_stack :: proc() {
    stack = new(Stack, context.temp_allocator)

    pusher_thread_handle := thread.create_and_start(perpetual_pusher)
    popper_thread_handle := thread.create_and_start(perpetual_popper)

    thread.join(pusher_thread_handle)
    thread.join(popper_thread_handle)
}