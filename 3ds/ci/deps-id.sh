#!/usr/bin/env bash
# Prints the dependency image's id for the checked-out commit: a hash of 3ds/deps and of the image's Dockerfile, so a
# change to either builds a new image.
set -euo pipefail

cd "$(dirname "$0")"
git -c safe.directory='*' rev-parse HEAD:3ds/deps HEAD:3ds/ci/deps.Dockerfile | sha1sum | cut -c1-40
