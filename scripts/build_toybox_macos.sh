#!/bin/bash
# TODO - can we unify the macos builds?
set -euxo pipefail
TOP="${PWD}/work/macos"
SRC="${TOP}/toybox-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
# Build happens in-tree
cp -r "${SRC}"/* .
make distclean
rm -f toybox*
make macos_defconfig
make -j"$(nproc)" \
	CFLAGS="-Os -target aarch64-apple-darwin"
make -j"$(nproc)"
cp toybox toybox-arm64
make clean
make -j"$(nproc)" \
	CFLAGS="-Os -target x86_64-apple-darwin"
cp toybox toybox-amd64
rm -fv "$TOP"/toybox || true
lipo -create toybox-amd64 toybox-arm64 -output "$TOP"/toybox
cd - || exit
rm -rf "$WORK"