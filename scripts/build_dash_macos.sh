#!/bin/bash
set -euo pipefail
TOP="${PWD}/work/macos"
SRC="${TOP}/dash-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
"${SRC}"/configure \
	CFLAGS="-Os -target aarch64-apple-darwin" \
	LDFLAGS="-s"
make -j"$(nproc)"
cp src/dash "$PWD"/dash-arm64
make clean
"${SRC}"/configure \
	CFLAGS="-Os -target x86_64-apple-darwin" \
	LDFLAGS="-s"
make -j"$(nproc)"
cp src/dash "$PWD"/dash-amd64
rm -v "$TOP"/dash || true
lipo -create dash-amd64 dash-arm64 -output "$TOP"/dash
cd - || exit
rm -rf "$WORK"