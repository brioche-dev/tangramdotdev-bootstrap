#!/bin/bash
# This script wraps a perl script to point to a `perl` in the same directory.
set -euo pipefail
dirname=${1%/*}
filename=${1##*/}
cd "$dirname" || exit
create_wrapper \
	--flavor "script" \
	--executable "$filename" \
	--interpreter "./perl" \
	--env "AC_MACRODIR=../share/autoconf" \
	--env "AUTOCONF_M4DIR=../share/autoconf"