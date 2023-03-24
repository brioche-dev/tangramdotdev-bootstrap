#!/bin/sh
DEB="$1"
DEST="$2"
WORKDIR=$(mktemp -d)
OUTDIR=$(mktemp -d)
cd "$WORKDIR" || true
ar -x "$DEB"
tar -xf data.tar.xz
cp -R bin "$OUTDIR"
tar -C "$OUTDIR" -cJf "$DEST" .
cd - || true
rm -r "$WORKDIR" "$OUTDIR"