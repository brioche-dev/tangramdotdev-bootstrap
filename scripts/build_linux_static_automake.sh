#!/bin/bash
# This script builds a wrapped automake distribution.
set -euo pipefail
source /envfile
"$SCRIPTS"/run_linux_static_autotools_build.sh automake "$1"
# NOTE - aclocal-1.16 and automake-1.16 are hardlinks to the non-versioned files, so relink here.
wrap() {
dirname=${1%/*}
filename=${1##*/}
cd "$dirname" || exit
	create_wrapper \
		--flavor "script" \
		--interpreter "./perl" \
		--executable "$filename" \
		--env "ACLOCAL_AUTOMAKE_DIR=../share/aclocal-1.16" \
		--env "ACLOCAL_PATH=../share/aclocal" \
		--env "AC_MACRODIR=../share/autoconf" \
		--env "AUTOCONF_M4DIR=../share/autoconf" \
		--env "autom4te_perllibdir=../share/autoconf" \
		--env "M4=./m4" \
		# --flag "'--system-acdir=../share/aclocal'"
}
wrap "${ROOTFS}/bin/aclocal"
wrap "${ROOTFS}/bin/aclocal-1.16"
# rm "${ROOTFS}/bin/aclocal-1.16"
# ln "${ROOTFS}/bin/aclocal" "${ROOTFS}/bin/aclocal-1.16"
wrap "${ROOTFS}/bin/automake"
wrap "${ROOTFS}/bin/automake-1.16"
# rm "${ROOTFS}/bin/automake-1.16"
# ln "${ROOTFS}/bin/automake" "${ROOTFS}/bin/automake-1.16"
