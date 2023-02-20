#!/bin/bash
# This script wraps a bash script to point to a `bash` in the same directory.
set -euo pipefail
dirname=${1%/*}
filename=${1##*/}
cd "$dirname" || exit
mv "$filename" ".$filename"
cat << EOW > $filename
#!/bin/sh
DIRNAME="\$(cd -- "\${0%/*}" && pwd)"
"\$DIRNAME/bash" "\$DIRNAME/.$filename" "\$@"
EOW
chmod +x "$filename"