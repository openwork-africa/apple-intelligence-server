#!/bin/sh
# Builds the release binary and packs it, with a checksum, into dist/.
set -eu

cd "$(dirname "$0")/.."
NAME=apple-intelligence-server
ARCHIVE="$NAME-macos-arm64.tar.gz"

swift build --configuration release --arch arm64
BINARY="$(swift build --configuration release --arch arm64 --show-bin-path)/$NAME"

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
mkdir -p "$STAGING/$NAME" dist
cp "$BINARY" LICENSE README.md "$STAGING/$NAME/"
tar -czf "dist/$ARCHIVE" -C "$STAGING" "$NAME"
(cd dist && shasum -a 256 "$ARCHIVE" > "$ARCHIVE.sha256")

echo "dist/$ARCHIVE"
cat "dist/$ARCHIVE.sha256"
