#!/usr/bin/env bash
# Fails when the dependency image wasn't built for this commit (run inside the image, from the checkout).
set -euo pipefail

want="$(bash "$(dirname "$0")/deps-id.sh")"
have="$(cat /work/deps-id 2>/dev/null || echo none)"
if [ "$want" != "$have" ]; then
    echo "the dependency image is $have, this commit needs $want" >&2
    exit 1
fi
echo "dependency image matches $want"
