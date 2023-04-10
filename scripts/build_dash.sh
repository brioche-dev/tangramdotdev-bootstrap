#!/bin/bash
set -euo pipefail
source /envfile
SRC="${TOP}/dash-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
"${SRC}"/configure \
	CFLAGS="-Os" \
	--enable-static
make -j"$(nproc)"
strip --strip-unneeded src/dash
cp src/dash "$TOP"
cd - || exit
rm -rf "$WORK"