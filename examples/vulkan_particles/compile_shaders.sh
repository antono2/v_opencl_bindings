#!/usr/bin/env sh
# Compiles the particle and trail GLSL shaders to the SPIR-V files used by the demo.
set -eu

: "${VULKAN_SDK:?Set VULKAN_SDK to the Vulkan SDK directory}"
GLSLC="$VULKAN_SDK/bin/glslc"
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

"$GLSLC" -O "$HERE/particles.vert" -o "$HERE/particles.vert.spv"
"$GLSLC" -O "$HERE/particles.frag" -o "$HERE/particles.frag.spv"
"$GLSLC" -O "$HERE/trails.vert" -o "$HERE/trails.vert.spv"
"$GLSLC" -O "$HERE/trails.frag" -o "$HERE/trails.frag.spv"
