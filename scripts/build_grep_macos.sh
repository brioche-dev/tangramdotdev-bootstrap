#!/bin/bash
set -euo pipefail
TOP="${PWD}/work/macos"
SRC="${TOP}/grep-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
"${SRC}"/configure \
	--host=aarch64-apple-darwin \
	CFLAGS="-Os -target aarch64-apple-darwin"
make -j"$(nproc)"
cp src/grep grep-arm64
make clean
"${SRC}"/configure \
	--host=x86_64-apple-darwin \
	CFLAGS="-Os -target x86_64-apple-darwin"
make -j"$(nproc)"
cp src/grep grep-amd64
rm -v "$TOP"/grep || true
lipo -create grep-amd64 grep-arm64 -output "$TOP"/grep
cp src/egrep "$TOP"/egrep
cp src/fgrep "$TOP"/fgrep
cd - || exit
rm -rf "$WORK"