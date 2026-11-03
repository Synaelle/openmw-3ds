#!/usr/bin/env bash
# The GitLab release of a tag (3ds/ci/gitlab.yml): waits until GitHub's release of the same tag is published, takes its
# notes and its Windows and macOS setup apps, uploads them with this pipeline's files to the project's package
# registry, then makes the release with a link to each.
set -euo pipefail

tag="$CI_COMMIT_TAG"
api="https://api.github.com/repos/$GITHUB_REPO/releases/tags/$tag"
mkdir -p github
# A draft isn't visible from outside: wait for the publication (GitHub publishes once every build is done).
for attempt in $(seq 1 100); do
    if curl -sSf -H 'Accept: application/vnd.github+json' "$api" -o github/release.json; then
        break
    fi
    echo "GitHub's release $tag isn't published yet (attempt $attempt), waiting"
    sleep 100
done
test -s github/release.json
for platform in Windows macOS; do
    name="OpenMW-3DS-$tag-$platform.zip"
    url=$(jq -r --arg n "$name" '.assets[] | select(.name == $n) | .browser_download_url' github/release.json)
    test -n "$url"
    curl -sSfL -o "github/$name" "$url"
done
jq -r '.body' github/release.json > github/notes.md

packages="$CI_API_V4_URL/projects/$CI_PROJECT_ID/packages/generic/openmw-3ds/$tag"
links=()
for file in dist/OpenMW-3DS-*-Python.zip dist/openmw3ds-*.cia dist-setup/*.tar.gz github/*.zip; do
    name=$(basename "$file")
    echo "uploading $name"
    curl -sSf --header "JOB-TOKEN: $CI_JOB_TOKEN" --upload-file "$file" "$packages/$name" > /dev/null
    links+=(--assets-link "{\"name\":\"$name\",\"url\":\"$packages/$name\",\"link_type\":\"package\"}")
done

release-cli create --name "$tag" --tag-name "$tag" --description github/notes.md "${links[@]}"
echo "released $tag"
