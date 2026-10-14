// Owned host storage for nonblocking transfers. Keep the owner until close/wait.
module opencl

@[nocopy]
pub struct OwnedTransfer[T] {
mut:
	storage    []T
	completion &OwnedEvent
}

// upload_owned copies values into stable storage before asynchronous submission.
pub fn (buffer &Buffer[T]) upload_owned(queue &OwnedCommandQueue, offset int, values []T, waits []Event) !&OwnedTransfer[T] {
	storage := values.clone()
	event := buffer.write_async(queue, offset, storage, waits)!
	return &OwnedTransfer[T]{
		storage:    storage
		completion: event
	}
}

pub fn (buffer &Buffer[T]) download_owned(queue &OwnedCommandQueue, offset int, count int, waits []Event) !&OwnedTransfer[T] {
	buffer.validate_transfer(queue, offset, count, 'owned download')!
	mut storage := []T{len: count}
	event := buffer.read_async(queue, offset, mut storage, waits)!
	return &OwnedTransfer[T]{
		storage:    storage
		completion: event
	}
}

// event returns a borrowed handle for dependency lists, not a new reference.
pub fn (transfer &OwnedTransfer[T]) event() Event {
	return transfer.completion.handle
}

// values waits and returns an independent host copy. The owner still needs close.
pub fn (transfer &OwnedTransfer[T]) values() ![]T {
	transfer.completion.wait()!
	return transfer.storage.clone()
}

// close waits before releasing storage. If wait fails, storage remains owned.
pub fn (mut transfer OwnedTransfer[T]) close() ! {
	if isnil(transfer.completion.handle) { return }
	transfer.completion.wait()!
	transfer.completion.close()!
	transfer.storage.clear()
}
