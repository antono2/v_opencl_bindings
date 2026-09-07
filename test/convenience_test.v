module main

import antono2.opencl as cl

fn test_error_preserves_operation_and_status() {
	err := cl.OpenCLError{
		operation: 'create buffer'
		status: cl.invalid_value
	}
	assert err.code() == -30
	assert err.msg() == 'create buffer: invalid_value (-30)'
}

fn test_check_accepts_success() {
	cl.check(cl.success, 'successful operation') or { assert false, err.msg() }
}

fn test_unknown_error_name_is_stable() {
	assert cl.error_code_name(cl.ErrorCode(-9999)) == 'opencl_error'
}
