#!/usr/bin/env bash
# Makes a release's files from its build (3ds/ci/build-cia.sh), into the out dir:
#   port-<version>.zip                  the port's files laid out as on the SD card, which the setup apps carry
#   OpenMW-3DS-<version>-Python.zip     the Python setup, with the port's files and its README
#   openmw3ds-<version>.cia             the CIA alone
#
#     3ds/ci/package.sh <version> <build dir> <out dir>
set -euo pipefail

version="${1:?usage: package.sh <version> <build dir> <out dir>}"
build="$(cd "${2:?build dir}" && pwd)"
mkdir -p "${3:?out dir}"
out="$(cd "$3" && pwd)"
root="$(cd "$(dirname "$0")/../.." && pwd)"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT

port_folder() {
    local dst="$1"
    mkdir -p "$dst/openmw/config" "$dst/cias"
    cp "$build/openmw.cfg" "$build/defaults.bin" "$dst/openmw/"
    cp -r "$build/resources" "$dst/openmw/resources"
    cp -r "$root/3ds/packaging/ui3ds" "$dst/openmw/ui3ds"
    cp "$root/3ds/packaging/settings-3ds.cfg" "$dst/openmw/config/settings.cfg"
    cp "$build/apps/openmw/openmw.cia" "$dst/cias/openmw3ds.cia"
}

readme() {
    sed "s/{VERSION}/$version/g" "$root/3ds/setup/packaging/README-$1.txt" > "$2"
}

port_folder "$stage/port"
(cd "$stage/port" && zip -qr "$out/port-$version.zip" cias openmw)

python="OpenMW-3DS-Setup-Python-$version"
port_folder "$stage/$python/port"
mkdir -p "$stage/$python/data"
cp "$root/3ds/setup/python/openmw3ds_setup.py" "$stage/$python/"
cp "$root"/3ds/setup/data/*.txt "$stage/$python/data/"
readme Python "$stage/$python/README.txt"
(cd "$stage" && zip -qr "$out/OpenMW-3DS-$version-Python.zip" "$python")

cp "$build/apps/openmw/openmw.cia" "$out/openmw3ds-$version.cia"
ls -l "$out"
