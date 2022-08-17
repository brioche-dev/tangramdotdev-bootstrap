#!/bin/bash

set -euxo pipefail

if [ "$#" -ne 1 ]; then
  echo "You must provide the directory to process: ./wrap-binaries.sh ./bootstrap_toolchain"
  exit 1
fi

export PREFIX="$1"
arch=$(uname -m)

if [ "$arch" = "aarch64" -o "$arch" = "arm64" ]; then
  dynamic_linker=ld-linux-aarch64.so.1
elif [ "$arch" = "x86_64" ]; then
  dynamic_linker=ld-linux-x86-64.so.2
else
  echo "Unsupported architecture!"
  exit 1
fi

# TODO - this is broken - on arm64, it still needs to be aarch64!
#triple="$arch"-unknown-linux-gnu
triple=aarch64-unknown-linux-gnu
#echo $triple


wrap_one() {
  # Rename file
  local dir=${1%/*}
  local file=${1##*/}
  mv "$1" "$dir"/"$file"_unwrapped
  # Create wrapper
  cat > "$1" <<EOF
#!/bin/sh
DIR=\$( cd -- "\${0%/*}" && pwd )
LIB_DIR=\${DIR}/../lib
INTERPRETER=\${LIB_DIR}/"$dynamic_linker"
\${INTERPRETER} --inhibit-cache --library-path \${LIB_DIR} \${DIR}/"$file"_unwrapped "\$@"
EOF
  # Make it executable
  chmod +x "$1"
}

wrap_five() {
  # Rename file
  local dir=${1%/*}
  local file=${1##*/}
  mv "$1" "$dir"/"$file"_unwrapped
  # Create wrapper
  cat > "$1" <<EOF
#!/bin/sh
DIR=\$( cd -- "\${0%/*}" && pwd )
LIB_DIR=\${DIR}/../../../../../lib
INTERPRETER=\${LIB_DIR}/"$dynamic_linker"
\${INTERPRETER} --inhibit-cache --library-path \${LIB_DIR} \${DIR}/"$file"_unwrapped "\$@"
EOF
  # Make it executable
  chmod +x "$1"
}

wrap_bin_dir() {
  # $1 is the file to wrap
  # This function wraps all executable binaries in the provided dir, excluding shell scripts
  # NOTE - the commented one only works on linux.
  # find "$1" -type f -executable -exec sh -c "file -i '{}' | grep -q 'x-executable; charset=binary'" \; -print | while read line; do wrap_one $line; done
  # This version just checks to see if any executable bit is set.
  find "$1" -type f -perm +ugo+x -exec sh -c "file '{}' | grep -q 'ELF 64-bit LSB executable'" \; -print | while read line; do wrap_one $line; done
}

wrap_bin_dir "$PREFIX"/usr/bin
wrap_bin_dir "$PREFIX"/toolchain/bin
wrap_bin_dir "$PREFIX"/toolchain/aarch64-linux-musl/bin
#wrap_five "$PREFIX"/usr/libexec/gcc/$triple/11.2.0/cc1
#wrap_five "$PREFIX"/usr/libexec/gcc/$triple/11.2.0/cc1plus
#wrap_five "$PREFIX"/usr/libexec/gcc/$triple/11.2.0/collect2
