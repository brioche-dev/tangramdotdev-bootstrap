#!/bin/bash
set -euo pipefail
TOP="${PWD}/work/macos"
SRC="${TOP}/coreutils-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
"${SRC}"/configure \
	--host=aarch64-apple-darwin \
	CFLAGS="-Os -target aarch64-apple-darwin"
make -j"$(nproc)"
cp src/expr expr-arm64
cp src/tr tr-arm64
make clean
"${SRC}"/configure \
	--host=x86_64-apple-darwin \
	CFLAGS="-Os -target x86_64-apple-darwin"
make -j"$(nproc)"
cp src/expr expr-amd64
cp src/tr tr-amd64
lipo -create expr-amd64 expr-arm64 -output "$TOP"/expr
lipo -create tr-amd64 tr-arm64 -output "$TOP"/tr
cd - || exit
rm -rf "$WORK"