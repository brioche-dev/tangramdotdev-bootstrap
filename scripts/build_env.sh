#!/bin/bash
set -euo pipefail
source /envfile
SRC="${TOP}/coreutils-${1}"
WORK=$(mktemp -d)
cd "$WORK" || exit
# NOTE - env is not one of the optionally installable programs.
# This builds everything, then just discards everything that isn't env.
FORCE_UNSAFE_CONFIGURE=1 "${SRC}"/configure \
	CFLAGS="-Os" \
	LDFLAGS="--static"
make -j"$(nproc)"
strip --strip-unneeded src/env
cp src/env "$TOP"
cd - || exit
rm -rf "$WORK"