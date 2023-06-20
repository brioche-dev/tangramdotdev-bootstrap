#!/bin/bash
# This script executes a Linux build for the requested architecture.
# docker/podman/etc
set -eu
cmd=$1
# arm64/amd64
arch=$2
script=$3
version=${4:-0.0.0}
name=${script%.*}
image="bootstrap_${arch}"
image_name="${arch}_${name}"
platform="linux/${arch}"
volmount=/bootstrap

"$cmd" run \
	--rm \
	--platform "$platform" \
	--name "$image_name" \
	-v "$PWD":"$volmount" \
	"$image" \
	/bin/bash "${volmount}/scripts/${script}" "$version"
