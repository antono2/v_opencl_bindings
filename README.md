# v_opencl_bindings

Generates V bindings for OpenCL from the canonical Khronos
[`cl.xml`](https://github.com/KhronosGroup/OpenCL-Docs/blob/main/xml/cl.xml)
registry.

## Generate

```sh
git clone --depth 1 https://github.com/KhronosGroup/OpenCL-Docs.git opencldocs
python3 src/main.py -registry opencldocs/xml/cl.xml opencl.v
v fmt -w src/opencl.v
```

The generated `src/opencl.v` is copied to the separately published `opencl`
V module.

The generated surface currently covers platform and device discovery plus a
complete basic compute path: contexts, command queues, buffers, source-program
builds, kernels, dispatch, reads, synchronization, build logs, and object
release. Additional core APIs and extensions will be added incrementally while
keeping generated output runtime-tested.

## Test

The smoke test uses the official OpenCL headers and the system ICD loader:

```sh
git clone --depth 1 https://github.com/KhronosGroup/OpenCL-Headers.git openclheaders
OPENCL_HEADERS=$PWD/openclheaders v -cc gcc run test
```

The smoke test builds and executes a small kernel, so an OpenCL implementation
is required. On Debian or Ubuntu, PoCL provides a suitable CPU implementation:

```sh
sudo apt install ocl-icd-opencl-dev pocl-opencl-icd
```
