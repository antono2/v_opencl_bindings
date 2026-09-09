# Vulkan particles

This example evolves a colorful particle galaxy with OpenCL and renders the same particle
buffer with Vulkan. Its preferred path exports a Vulkan allocation and imports it into OpenCL;
systems without compatible external-memory and external-semaphore support use per-frame staging.

The implementation is split into independently testable layers: deterministic OpenCL simulation,
display-independent smoke tests, Vulkan/OpenCL device matching, interoperability negotiation, and
an interactive Vulkan renderer. On a qualifying device the live renderer uses the exported Vulkan
vertex allocation directly as its OpenCL simulation buffer. Other systems retain the same renderer
and use a host-staged upload each frame. That fallback enables only the swapchain extension and
does not require OpenCL and Vulkan to select the same physical device.

On qualifying hardware the smoke runner also exercises a real Vulkan allocation imported into
OpenCL and a two-way opaque-FD binary semaphore handshake.

The Vulkan shaders consume each `Particle` directly as two `vec4` vertex attributes. They render
soft circular point sprites with additive blending and color derived from velocity. Rebuild the
checked-in SPIR-V after editing GLSL with `./compile_shaders.sh`.

Install the example-only V modules and Linux development packages before building from source:

```sh
v install antono2.opencl
v install antono2.vulkan
v install antono2.glfw
sudo apt install ocl-icd-opencl-dev libvulkan-dev libglfw3-dev
```

The source imports the published modules through their VPM names, so no manual
move or symlink inside `.vmodules` is needed.

```sh
# Interactive renderer
v -cc gcc run examples/vulkan_particles --window
v -cc gcc run examples/vulkan_particles --frames=120
v -cc gcc run examples/vulkan_particles --staged
v -cc gcc run examples/vulkan_particles --zero-copy --frames=120

# Headless smoke test (does not open a window)
v -cc gcc run examples/vulkan_particles
v -cc gcc run examples/vulkan_particles --particles=4096

# TinyCC is supported as well
v -cc tcc run examples/vulkan_particles --particles=4096
```

TinyCC requires `antono2.vulkan` 1.7.0 or newer for its deep-bound Volk loader.

## Tested hardware

- NVIDIA GeForce GTX 1060 6GB on Linux: UUID-matched opaque-FD external memory,
  Vulkan-to-OpenCL-to-Vulkan semaphore synchronization, and 300 frames with
  32,768 particles passed using GCC.

Running without a renderer option intentionally performs only the display-independent smoke test
and prints a reminder that no window will be opened. Run with `--window` for the interactive
renderer or `--help` for the complete command-line interface. The original `PARTICLE_COUNT`,
`PARTICLES_WINDOW`, `PARTICLES_FRAMES`, `PARTICLES_FORCE_STAGED`, and
`PARTICLES_REQUIRE_ZERO_COPY` environment variables remain supported for scripts and compatibility.

Startup reports the selected OpenCL and Vulkan devices and either `zero-copy` or a precise reason
for selecting `staged fallback`. Device UUIDs must match before external memory is considered.
`--window` additionally verifies GLFW surface creation, graphics/presentation queue
selection, swapchain negotiation, image enumeration, image-view creation, and the live particle
loop. The final console line includes `(zero-copy)` or `(staged)`, confirming the path actually used
by the renderer. `--frames` limits the loop for automated smoke tests; zero means run until
the window is closed. Swapchain resources are rebuilt when a resize makes them suboptimal or
out-of-date; even a skipped zero-copy frame completes its external-semaphore ownership cycle.
`--zero-copy` makes capability or UUID mismatches fatal, so it is suitable for validating the
external-memory and external-semaphore path on supported hardware.

Each particle also gets a velocity-colored motion streak rendered from the shared particle data.
Move the mouse to steer the third attractor, press Space to pause/resume, R to reset, T to toggle
the streaks, and Escape to exit. The title reports particle count, average FPS, transfer backend,
trail state, and pause state. The live zero-copy loop uses reusable opaque-FD binary semaphores
for the Vulkan-to-OpenCL and OpenCL-to-Vulkan ownership handoffs, without per-frame host waits.
