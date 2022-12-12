#!/bin/bash
# This script builds a wrapped autoconf distribution.
set -euo pipefail
wrapAutom4te() {
dirname=${1%/*}
filename=${1##*/}
cd "$dirname" || exit
	create_wrapper \
		--flavor "script" \
		--interpreter "./perl" \
		--executable "$filename" \
		--env "autom4te_perllibdir=../share/autoconf" \
		--env "AC_MACRODIR=../share/autoconf" \
		--env "AUTOCONF_M4DIR=../share/autoconf" \
		--env "AUTOM4TE=./autom4te" \
		--env "M4=./m4" \
		--env "trailer_m4=../share/autoconf/autoconf/trailer.m4"
}
source /envfile
"$SCRIPTS"/run_linux_static_autotools_build.sh autoconf "$1"
"$SCRIPTS"/wrap_bash_script.sh "${ROOTFS}/bin/autoconf"
"$SCRIPTS"/wrap_bash_script.sh "${ROOTFS}/bin/autoreconf"
"$SCRIPTS"/wrap_perl_script.sh "${ROOTFS}/bin/autoheader"
wrapAutom4te "${ROOTFS}/bin/autom4te"
"$SCRIPTS"/wrap_perl_script.sh "${ROOTFS}/bin/autoscan"
"$SCRIPTS"/wrap_perl_script.sh "${ROOTFS}/bin/autoupdate"
"$SCRIPTS"/wrap_perl_script.sh "${ROOTFS}/bin/ifnames"
