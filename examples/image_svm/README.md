# Typed images and SVM

This example exercises the OpenCL `0.4` memory APIs on the first available
device. It copies a 2×2 RGBA image through an OpenCL image kernel and owned
sampler. When the device advertises buffer shared virtual memory, it also binds
an owned typed SVM allocation directly to a second kernel.

```sh
v -cc gcc run examples/image_svm
```

The image path requires support for 2D `CL_RGBA`/`CL_UNORM_INT8` images. The
SVM path is optional and reports a skip on OpenCL 1.x devices or OpenCL 3.0
devices that do not advertise coarse- or fine-grained buffer SVM.

`Image2D[T]` treats `T` as one complete pixel and rejects a format whose storage
size differs from `sizeof(T)`. `SvmAllocation[T]` performs checked OpenCL copy
operations; coarse-grained host pointer access additionally requires explicit
`map()` and `unmap()` calls.
