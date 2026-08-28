#+feature using-stmt

package lockfree

import "core:fmt"
import "core:thread"
import "core:time"

QUEUE_SIZE :: 5

perpetual_producer :: proc(q: []int) {
    absolute_write_index: u64
    for true {
        queue_write_index := absolute_write_index % QUEUE_SIZE
        q[queue_write_index] = cast(int)absolute_write_index
        fmt.printfln("write :: queue_idx=%d | val=%d", queue_write_index, absolute_write_index)

        absolute_write_index += 1
        time.sleep(time.Second / 2)
    }
}

perpetual_consumer :: proc(q: []int) {
    absolute_read_index: u64
    for true {
        queue_read_index := absolute_read_index % QUEUE_SIZE
        val := q[queue_read_index]
        fmt.printfln("read :: queue_idx=%d | val=%d", queue_read_index, val)

        absolute_read_index += 1
        time.sleep(time.Second * 1)
    }
}

main :: proc() {
    job_queue := make([]int, QUEUE_SIZE, context.temp_allocator)

    producer_thread_handle := thread.create_and_start_with_poly_data(job_queue, perpetual_producer)
    consumer_thread_handle := thread.create_and_start_with_poly_data(job_queue, perpetual_consumer)

    thread.join(producer_thread_handle)
    thread.join(consumer_thread_handle)
}