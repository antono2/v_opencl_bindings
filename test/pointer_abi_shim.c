#include <CL/opencl.h>
#include <stddef.h>
#include <stdint.h>

static cl_platform_id *expected_platform_array;
static int blocking_write_calls;
static int blocking_read_calls;
static int kernel_enqueue_calls;

void opencl_pointer_shim_reset(void) {
    expected_platform_array = NULL;
    blocking_write_calls = 0;
    blocking_read_calls = 0;
    kernel_enqueue_calls = 0;
}

void opencl_pointer_shim_expect_platform_array(void *pointer) {
    expected_platform_array = (cl_platform_id *)pointer;
}

int opencl_pointer_shim_blocking_write_calls(void) {
    return blocking_write_calls;
}

int opencl_pointer_shim_blocking_read_calls(void) {
    return blocking_read_calls;
}

int opencl_pointer_shim_kernel_enqueue_calls(void) {
    return kernel_enqueue_calls;
}

CL_API_ENTRY cl_int CL_API_CALL clGetPlatformIDs(
    cl_uint num_entries,
    cl_platform_id *platforms,
    cl_uint *num_platforms) {
    if (num_entries == 0) {
        if (platforms != NULL || num_platforms == NULL) {
            return CL_INVALID_VALUE;
        }
        *num_platforms = 2;
        return CL_SUCCESS;
    }
    if (num_entries < 2 || platforms == NULL || platforms != expected_platform_array) {
        return CL_INVALID_VALUE;
    }
    platforms[0] = (cl_platform_id)(uintptr_t)0x1010;
    platforms[1] = (cl_platform_id)(uintptr_t)0x2020;
    if (num_platforms != NULL) {
        *num_platforms = 2;
    }
    return CL_SUCCESS;
}

CL_API_ENTRY cl_int CL_API_CALL clEnqueueWriteBuffer(
    cl_command_queue command_queue,
    cl_mem buffer,
    cl_bool blocking_write,
    size_t offset,
    size_t size,
    const void *ptr,
    cl_uint num_events_in_wait_list,
    const cl_event *event_wait_list,
    cl_event *event) {
    (void)command_queue;
    (void)buffer;
    (void)offset;
    if (blocking_write != CL_TRUE || size == 0 || ptr == NULL) {
        return CL_INVALID_VALUE;
    }
    if (num_events_in_wait_list != 0 || event_wait_list != NULL || event != NULL) {
        return CL_INVALID_EVENT_WAIT_LIST;
    }
    blocking_write_calls++;
    return CL_SUCCESS;
}

CL_API_ENTRY cl_int CL_API_CALL clEnqueueReadBuffer(
    cl_command_queue command_queue,
    cl_mem buffer,
    cl_bool blocking_read,
    size_t offset,
    size_t size,
    void *ptr,
    cl_uint num_events_in_wait_list,
    const cl_event *event_wait_list,
    cl_event *event) {
    (void)command_queue;
    (void)buffer;
    (void)offset;
    if (blocking_read != CL_TRUE || size == 0 || ptr == NULL) {
        return CL_INVALID_VALUE;
    }
    if (num_events_in_wait_list != 0 || event_wait_list != NULL || event != NULL) {
        return CL_INVALID_EVENT_WAIT_LIST;
    }
    blocking_read_calls++;
    return CL_SUCCESS;
}

CL_API_ENTRY cl_int CL_API_CALL clEnqueueNDRangeKernel(
    cl_command_queue command_queue,
    cl_kernel kernel,
    cl_uint work_dim,
    const size_t *global_work_offset,
    const size_t *global_work_size,
    const size_t *local_work_size,
    cl_uint num_events_in_wait_list,
    const cl_event *event_wait_list,
    cl_event *event) {
    (void)command_queue;
    (void)kernel;
    (void)local_work_size;
    if (work_dim != 1 || global_work_offset != NULL || global_work_size == NULL) {
        return CL_INVALID_VALUE;
    }
    if (num_events_in_wait_list != 0 || event_wait_list != NULL || event != NULL) {
        return CL_INVALID_EVENT_WAIT_LIST;
    }
    kernel_enqueue_calls++;
    return CL_SUCCESS;
}
