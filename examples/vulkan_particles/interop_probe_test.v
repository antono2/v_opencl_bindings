module main

fn test_extension_sets_require_complete_tokens() {
	extensions := 'cl_khr_external_memory cl_khr_external_memory_opaque_fd cl_khr_semaphore'
	assert has_all_extensions(extensions, ['cl_khr_external_memory'])
	assert has_all_extensions(extensions, ['cl_khr_external_memory',
		'cl_khr_external_memory_opaque_fd'])
	assert !has_all_extensions(extensions, ['cl_khr_external_semaphore'])
	assert !has_all_extensions(extensions, ['cl_khr_external'])
}

fn test_uuid_comparison() {
	left := [u8(0), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]!
	mut same := [u8(0), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]!
	mut different := [u8(0), 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]!
	different[15] = 16
	assert uuid_equal(left, &same[0])
	assert !uuid_equal(left, &different[0])
}
