#!/bin/bash
# This script builds help2man.
set -euo pipefail
source /envfile
"$SCRIPTS"/run_linux_static_autotools_build.sh help2man "$1"
"$SCRIPTS"/wrap_perl_script.sh "${ROOTFS}/bin/help2man"