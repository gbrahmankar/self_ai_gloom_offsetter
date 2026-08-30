#+feature using-stmt

package lockfree

import "core:fmt"
import "base:intrinsics"
import "core:thread"
import "core:time"

QUEUE_SIZE :: 5

Cache_Line_U64 :: struct #align(64) {
    value: u64,
}

write_index: Cache_Line_U64
read_index: Cache_Line_U64

perpetual_producer :: proc(q: []int) {
    for true {
        w := intrinsics.atomic_load_explicit(&write_index.value, .Relaxed)
        next_write_idx := (w + 1) % QUEUE_SIZE

        if next_write_idx == intrinsics.atomic_load_explicit(&read_index.value, .Acquire) {
            fmt.printfln("write :: queue_full :: write_attempted_at_index=%d", w)
            time.sleep(time.Second / 5)
            continue
        }

        q[w] = cast(int)w
        fmt.printfln("write :: queue_idx=%d | val=%d", w, w)

        intrinsics.atomic_store_explicit(&write_index.value, next_write_idx, .Release)
        time.sleep(time.Second / 5)
    }
}

perpetual_consumer :: proc(q: []int) {
    for true {
        r := intrinsics.atomic_load_explicit(&read_index.value, .Acquire)

        if r == intrinsics.atomic_load_explicit(&write_index.value, .Acquire) {
            fmt.printfln("read :: queue_empty :: read_attempted_at_index=%d", r)
            continue
        }

        fmt.printfln("read :: queue_idx=%d | val=%d", r, q[r])

        intrinsics.atomic_store_explicit(&read_index.value, (r + 1) % QUEUE_SIZE, .Release)
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