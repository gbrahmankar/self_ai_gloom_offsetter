#+feature using-stmt

package lockfree

import "core:fmt"
import "core:time"

QUEUE_SIZE :: 10

perpetual_producer :: proc(q: []int) {
    absolute_write_index: u64
    for true {
        queue_write_index := absolute_write_index % QUEUE_SIZE
        q[queue_write_index] = cast(int)absolute_write_index
        fmt.printfln("write :: queue_idx=%d | val=%d", queue_write_index, absolute_write_index)

        absolute_write_index += 1
        time.sleep(time.Second * 1)
    }
}

perpetual_consumer :: proc(q: []int) {
    absolute_read_index: u64
    for true {
        queue_write_index := absolute_read_index % QUEUE_SIZE
        q[queue_write_index] = cast(int)absolute_write_index
        fmt.printfln("write :: queue_idx=%d | val=%d", queue_write_index, absolute_write_index)

        absolute_write_index += 1
        time.sleep(time.Second * 1)
    }
}

main :: proc() {
    job_queue := make([]int, QUEUE_SIZE, context.temp_allocator) 

    perpetual_producer(job_queue)
}