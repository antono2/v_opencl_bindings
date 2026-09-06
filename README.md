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

The initial generated surface covers platform and device discovery plus their
information-query functions. Additional core API versions and extensions will
be added incrementally while keeping generated output ABI-tested.

## Test

The smoke test uses the official OpenCL headers and the system ICD loader:

```sh
git clone --depth 1 https://github.com/KhronosGroup/OpenCL-Headers.git openclheaders
OPENCL_HEADERS=$PWD/openclheaders v -cc gcc run test
```

An installed OpenCL implementation is optional. A machine with only an ICD
loader may correctly report that no platform is available.
