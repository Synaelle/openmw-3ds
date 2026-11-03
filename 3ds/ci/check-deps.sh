#!/usr/bin/env bash
# Fails when the dependency image wasn't built from this commit's 3ds/deps (run inside the image, from the checkout).
set -euo pipefail

want="$(git -c safe.directory='*' -C "$(dirname "$0")" rev-parse HEAD:3ds/deps)"
have="$(cat /work/deps-tree 2>/dev/null || echo none)"
if [ "$want" != "$have" ]; then
    echo "the dependency image was built from 3ds/deps $have, this commit has $want" >&2
    exit 1
fi
echo "dependency image matches 3ds/deps $want"
