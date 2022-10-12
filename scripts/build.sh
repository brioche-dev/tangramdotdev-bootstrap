#!/bin/bash
# This is the top-level driver script for producing all platform bootstrap bundles.
set -euxo pipefail
DATE=$(date +"%Y%m%d")
VOLMOUNT="/bootstrap"
SCRIPT="build_linux_rootfs.sh"
IMAGE="alpine:3.16.2"

# macos
#sh ./build_macos_bootstrap.sh &

# aarch64-linux
{
  docker run --rm --platform linux/arm64/v8 --name "aarch64-bootstrap" -v "$PWD":"$VOLMOUNT" "$IMAGE" /bin/sh "$VOLMOUNT"/"$SCRIPT" &>"$PWD"/aarch64_linux.log
  echo "Built aarch64" &&
    tar -C aarch64/rootfs -cJf bootstrap_linux_aarch64_"$DATE".tar.xz . &&
    echo "Compressed aarch64" &&
    b3sum bootstrap_linux_aarch64_"$DATE".tar.xz | tee "$PWD"/aarch64_linux.log
} &

# x86_64-linux
{
  docker run --rm --platform linux/amd64 --name "x86_64-bootstrap" -v "$PWD":"$VOLMOUNT" "$IMAGE" /bin/sh "$VOLMOUNT"/"$SCRIPT" &>"$PWD"/x86_64_linux.log
  echo "Built x86_64" &&
    tar -C x86_64/rootfs -cJf bootstrap_linux_x86_64_"$DATE".tar.xz . &&
    echo "Compressed x86_64" &&
    b3sum bootstrap_linux_x86_64_"$DATE".tar.xz | tee "$PWD"/x86_64_linux.log
} &