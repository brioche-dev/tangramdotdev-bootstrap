#!/bin/bash
# This script wraps a python script to point to a `python3` in the same directory.
set -euo pipefail
dirname=${1%/*}
filename=${1##*/}
cd "$dirname" || exit
mv "$filename" ".$filename"
cat << EOW > "$filename"
#!/bin/sh
DIRNAME="\$(cd -- "\${0%/*}" && pwd)"
"\$DIRNAME/python3" "\$DIRNAME/.$filename" "\$@"
EOW
chmod +x "$filename"