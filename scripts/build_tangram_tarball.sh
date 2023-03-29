#!/bin/sh
EXE="$1"
DEST="$2"
WORK=$(mktemp -d)
mkdir -p "${WORK}/bin"
cp "$EXE" "${WORK}/bin"
tar -C "$WORK" -cJf "$DEST" .
rm -rf "$WORK" 