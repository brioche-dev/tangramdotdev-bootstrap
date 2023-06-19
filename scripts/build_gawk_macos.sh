#!/bin/bash
set -euo pipefail
TOP="${PWD}/work/macos"
SRC="${TOP}/gawk-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
"${SRC}"/configure \
	CFLAGS="-Os -target aarch64-apple-darwin"
make -j"$(nproc)"
cp gawk gawk-arm64
make clean
"${SRC}"/configure \
	CFLAGS="-Os -target x86_64-apple-darwin"
make -j"$(nproc)"
cp gawk gawk-amd64
rm -v "$TOP"/gawk || true
lipo -create gawk-amd64 gawk-arm64 -output "$TOP"/gawk
cd - || exit
rm -rf "$WORK"