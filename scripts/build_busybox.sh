#!/bin/bash
set -euo pipefail
source /envfile
SRC="${TOP}/busybox-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
make KBUILD_SRC="$SRC" -f "$SRC"/Makefile defconfig
sed -i 's/^# CONFIG_STATIC is not set$/CONFIG_STATIC=y/' .config
make -j"$(nproc)"
cp ./busybox "${TOP}"
cd - || exit
rm -rf "$WORK"