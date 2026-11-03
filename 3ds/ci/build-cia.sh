#!/usr/bin/env bash
# Builds a release of the game (no debug tools, the version shown on screen) in the dependency image
# (3ds/ci/deps.Dockerfile), whose dependencies it links as 3ds/.deps.
#
#     3ds/ci/build-cia.sh <version> [build dir]
#
# The build dir (3ds/build/openmw-release by default) then holds openmw.elf, apps/openmw/openmw.cia and the files the
# port ships next to it (openmw.cfg, defaults.bin, resources).
set -euo pipefail

version="${1:?usage: build-cia.sh <version> [build dir]}"
root="$(cd "$(dirname "$0")/../.." && pwd)"
build="${2:-$root/3ds/build/openmw-release}"
deps="${OPENMW3DS_DEPS_DIR:-/work/3ds/.deps}"

if [ ! -e "$root/3ds/.deps" ]; then
    ln -s "$deps" "$root/3ds/.deps"
fi
test -f "$root/3ds/.deps/3ds/lib/libosg.a" || { echo "no dependencies in $root/3ds/.deps" >&2; exit 1; }

export DEVKITPRO=/opt/devkitpro DEVKITARM=/opt/devkitpro/devkitARM
# -Os keeps the code small: the image counts against the 178 MB memory region, so every MB of code is a MB less heap.
flags="-g -Os -DNDEBUG"
echo "configuring $version in $build"
cmake -S "$root" -B "$build" -G Ninja -C "$root/3ds/cmake/openmw-3ds-cache.cmake" \
    -DCMAKE_TOOLCHAIN_FILE="$DEVKITPRO/cmake/3DS.cmake" -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    "-DCMAKE_CXX_FLAGS_RELWITHDEBINFO=$flags" "-DCMAKE_C_FLAGS_RELWITHDEBINFO=$flags" \
    -DOPENMW3DS_DEBUG=OFF "-DOPENMW3DS_RELEASE_VERSION=$version"
echo "building with $(nproc) jobs"
cmake --build "$build" -j "$(nproc)"
test -f "$build/apps/openmw/openmw.cia"
"$DEVKITARM/bin/arm-none-eabi-size" -A "$build/openmw.elf" | grep -E '^\.(text|data|bss|rodata) '
