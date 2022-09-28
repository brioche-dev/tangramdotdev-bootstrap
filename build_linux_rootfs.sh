#!/bin/bash
# This script creates a musl-based bootstrap toolchain.  Intended to run on Alpine Linux.

### SETUP
apk add alpine-sdk autoconf automake bash bison file flex gawk gettext-dev git indent m4 libbz2 libtool ncurses-dev wget xz zlib

# Run remainder of script in actual bash.
bash
set -euxo pipefail

NPROC=$(nproc)
ARCH=$(uname -m)
SHARED="/bootstrap"
TOP="$SHARED/$ARCH"
SOURCES="$SHARED/sources"
BUILDS="$TOP/builds"
ROOTFS="$TOP/rootfs"

# move into the shared dir.
cd "$SHARED"

prepareDir() {
	mkdir -p "$SOURCES" # this should already be mounted in
	rm -rf "$BUILDS" && mkdir -p "$BUILDS"
	rm -rf "$ROOTFS"
	mkdir -p "$ROOTFS"/bin
	mkdir -p "$ROOTFS"/include
	mkdir -p "$ROOTFS"/share
	mkdir -p "$ROOTFS"/tmp
}

# download a tarball
# TODO - verify sig
fetchSource() {
	local filename="${1##*/}"
	if [ ! -f "$SOURCES"/"$filename" ]; then
		cd "$SOURCES"
		wget "$1"
		cd -
	fi
}

unpackSource() {
	sourcePath="$SOURCES"/"$1"
	cd "$BUILDS"
	tar xf "$sourcePath"
	cd -
}

MAKE_VER="make-4.3"
MAKE_PKG="$MAKE_VER.tar.gz"
MAKE_URL="https://ftp.gnu.org/gnu/make/$MAKE_PKG"
prepareMake() {
	fetchSource "$MAKE_URL"
	unpackSource "$MAKE_PKG"
	cd "$BUILDS"/"$MAKE_VER"
	./configure \
		LDFLAGS="-static" \
		--prefix="$ROOTFS"
	./build.sh
	./make install
	cd -
}

# toybox
TOYBOX="toybox-$ARCH"
TOYBOX_URL="http://landley.net/toybox/bin/$TOYBOX"
prepareToybox() {
	cd "$ROOTFS"/bin
	wget "$TOYBOX_URL"
	mv "$TOYBOX" toybox
	chmod +x toybox
	cd -
	cd "$ROOTFS"/bin
	for i in $(./toybox); do ln -s toybox "$i"; done
	cd -
}

# coreutils
COREUTILS_VER="coreutils-9.1"
COREUTILS_PKG="$COREUTILS_VER.tar.xz"
COREUTILS_URL="https://ftp.gnu.org/gnu/coreutils/$COREUTILS_PKG"
prepareCoreutils() {
	fetchSource "$COREUTILS_URL"
	unpackSource "$COREUTILS_PKG"
	cd "$BUILDS"/"$COREUTILS_VER"
	export CFLAGS="-static -Os -ffunction-sections -fdata-sections"
	FORCE_UNSAFE_CONFIGURE=1 ./configure \
		CFLAGS="$CFLAGS" \
		LDFLAGS="-Wl,--gc-sections" \
		--prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	unset CFLAGS
	cd -
}

DIFFUTILS_VER="diffutils-3.8"
DIFFUTILS_PKG="$DIFFUTILS_VER.tar.xz"
DIFFUTILS_URL="https://ftp.gnu.org/gnu/diffutils/$DIFFUTILS_PKG"
prepareDiffutils() {
	fetchSource "$DIFFUTILS_URL"
	unpackSource "$DIFFUTILS_PKG"
	cd "$BUILDS"/"$DIFFUTILS_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

FINDUTILS_VER="findutils-4.9.0"
FINDUTILS_PKG="$FINDUTILS_VER.tar.xz"
FINDUTILS_URL="https://ftp.gnu.org/gnu/findutils/$FINDUTILS_PKG"
prepareFindutils() {
	fetchSource "$FINDUTILS_URL"
	unpackSource "$FINDUTILS_PKG"
	cd "$BUILDS"/"$FINDUTILS_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

# gawk
GAWK_VER="gawk-5.1.1"
GAWK_PKG="$GAWK_VER.tar.xz"
GAWK_URL="https://ftp.gnu.org/gnu/gawk/$GAWK_PKG"
prepareGawk() {
	fetchSource "$GAWK_URL"
	unpackSource "$GAWK_PKG"
	cd "$BUILDS"/"$GAWK_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	unset CC
	cd -
}

# grep
GREP_VER="grep-3.7"
GREP_PKG="$GREP_VER.tar.xz"
GREP_URL="https://ftp.gnu.org/gnu/grep/$GREP_PKG"
prepareGrep() {
	fetchSource "$GREP_URL"
	unpackSource "$GREP_PKG"
	cd "$BUILDS"/"$GREP_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

# texinfo
TEXINFO_VER="texinfo-6.8"
TEXINFO_PKG="$TEXINFO_VER.tar.xz"
TEXINFO_URL="https://ftp.gnu.org/gnu/texinfo/$TEXINFO_PKG"
prepareTexinfo() {
	fetchSource "$TEXINFO_URL"
	unpackSource "$TEXINFO_PKG"
	cd "$BUILDS"/"$TEXINFO_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

# # linux-headers
# LINUX_VER="5.18.4"
# LINUX="linux-$LINUX_VER"
# LINUX_PKG="$LINUX.tar.xz"
# LINUX_URL="https://cdn.kernel.org/pub/linux/kernel/v5.x/$LINUX_PKG"
# LINUX_HEADER_PREFIX="$ROOTFS/include/linux"
# prepareLinuxHeaders() {
#     fetchSource "$LINUX_URL" "$LINUX_PKG"
#     unpackSource "$LINUX_PKG"
# 	cd "$BUILDS"/"$LINUX"
# 	make mrproper
# 	make headers
# 	mkdir -p "$LINUX_HEADER_PREFIX"
# 	cp -r usr/include "$LINUX_HEADER_PREFIX"
# 	find "$LINUX_HEADER_PREFIX" -type f ! -name '*.h' -delete
# 	mkdir -p "$LINUX_HEADER_PREFIX"/include/config
# 	echo "$LINUX_VER"-default > "$LINUX_HEADER_PREFIX"/include/config/kernel.release
# 	cd -
# }
if [ "$ARCH" = "aarch64" ]; then
	LINUX_HEADERS="linux-headers-prebuild-aarch64-linux"
else
	LINUX_HEADERS="linux-headers-prebuild-amd64-linux"
fi
LINUX_HEADERS_PKG="$LINUX_HEADERS.tar.xz"
LINUX_HEADERS_URL="https://github.com/tangramdotdev/bootstrap/releases/download/v0.0.0/$LINUX_HEADERS_PKG"
LINUX_HEADER_PREFIX="$ROOTFS/include/linux"
prepareLinuxHeaders() {
	fetchSource "$LINUX_HEADERS_URL"
	unpackSource "$LINUX_HEADERS_PKG"
	mkdir -p "$LINUX_HEADER_PREFIX"
	mv "$BUILDS"/include "$LINUX_HEADER_PREFIX"
}

# bison
BISON_VER="bison-3.8.2"
BISON_PKG="$BISON_VER.tar.xz"
BISON_URL="https://ftp.gnu.org/gnu/bison/$BISON_PKG"
prepareBison() {
	fetchSource "$BISON_URL"
	unpackSource "$BISON_PKG"
	cd "$BUILDS"/"$BISON_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

GZIP_VER="gzip-1.12"
GZIP_PKG="$GZIP_VER.tar.xz"
GZIP_URL="https://ftp.gnu.org/gnu/gzip/$GZIP_PKG"
prepareGzip() {
	fetchSource "$GZIP_URL"
	unpackSource "$GZIP_PKG"
	cd "$BUILDS"/"$GZIP_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

M4_VER="m4-1.4.19"
M4_PKG="$M4_VER.tar.xz"
M4_URL="https://ftp.gnu.org/gnu/m4/$M4_PKG"
preparem4() {
	fetchSource "$M4_URL"
	unpackSource "$M4_PKG"
	cd "$BUILDS"/"$M4_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

# patchelf
preparePatchelf() {
	cd "$BUILDS"
	git clone https://github.com/NixOS/patchelf.git
	cd patchelf
	./bootstrap.sh
	./configure \
		LDFLAGS="-static" \
		--prefix="$ROOTFS"
	make -j"$NPROC"
	make install
}

# perl
preparePerl() {
	mkdir -p "$BUILDS"/staticperl
	cd "$BUILDS"/staticperl
	wget https://fastapi.metacpan.org/source/MLEHMANN/App-Staticperl-1.46/bin/staticperl
	chmod +x ./staticperl
	./staticperl install
	# FIXME - deteermine more minimal module set and configure here to save considerable build time and bundle size.
	./staticperl mkperl -v --strip ppi --incglob '*'
	mv ./perl "$ROOTFS"/bin/.perl_unwrapped
	# FIXME - can we produce a fully static binary and avoid the wrapper?
	cat >"$ROOTFS"/bin/perl <<EOW
#!/bin/sh
DIR=\$(cd -- "\${0%/*}" && pwd)
LIB_DIR=\${DIR}/../toolchain/lib
INTERPRETER=\${LIB_DIR}/ld-musl-$ARCH.so.1
\${INTERPRETER} --preload \${LIB_DIR}/libc.so -- \${DIR}/.perl_unwrapped "\$@"
EOW
	chmod +x "$ROOTFS"/bin/perl
	cd -
}

GPERF_VER="gperf-3.1"
GPERF_PKG="$GPERF_VER.tar.gz"
GPERF_URL="https://ftp.gnu.org/gnu/gperf/$GPERF_PKG"
prepareGperf() {
	fetchSource "$GPERF_URL"
	unpackSource "$GPERF_PKG"
	cd "$BUILDS"/"$GPERF_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

AUTOCONF_VER="autoconf-2.71"
AUTOCONF_PKG="$AUTOCONF_VER.tar.xz"
AUTOCONF_URL="https://ftp.gnu.org/gnu/autoconf/autoconf-2.71.tar.xz"
prepareAutoconf() {
	fetchSource "$AUTOCONF_URL"
	unpackSource "$AUTOCONF_PKG"
	cd "$BUILDS"/"$AUTOCONF_VER"
	./configure LDFLAGS="-static" --prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	cd -
}

XZ_VER="xz-5.2.6"
XZ_PKG="$XZ_VER.tar.xz"
XZ_URL="https://tukaani.org/xz/$XZ_PKG"
prepareXz() {
	fetchSource "$XZ_URL"
	unpackSource "$XZ_PKG"
	cd "$BUILDS"/"$XZ_VER"
	./configure \
		LDFLAGS="--static" \
		--prefix="$ROOTFS" \
		--disable-debug \
		--disable-dependency-tracking \
		--disable-silent-rules \
		--disable-shared \
		--disable-nls
	make -j"$NPROC"
	make install
	cd -
}

FLEX_VER="2.6.4"
FLEX_PKG="flex-$FLEX_VER.tar.gz"
FLEX_URL="https://github.com/westes/flex/releases/download/v$FLEX_VER/$FLEX_PKG"
prepareFlex() {
	pushd "$BUILDS"
	fetchSource "$FLEX_URL"
	unpackSource "$FLEX_PKG"
	pushd "$BUILDS"/"flez-$FLEX_VER"
	# NOTE - needs to use --static, not just -static, or else libtool mode=link discards it (?!)
	ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes ./configure \
		--disable-shared \
		--enable-static \
		LDFLAGS="--static" \
		--prefix="$ROOTFS"
	make -j"$NPROC"
	make install
	popd
	popd
}

# python
PYVER="3.10.7"
PYTHON_VER="Python-$PYVER"
PYTHON_PKG="$PYTHON_VER.tar.xz"
PYTHON_URL=https://www.python.org/ftp/python/"$PYVER"/"$PYTHON_PKG"
preparePython() {
	fetchSource "$PYTHON_URL"
	unpackSource "$PYTHON_PKG"
	cd "$BUILDS"/"$PYTHON_VER"
	patch -ruN Modules/Setup <"$SHARED"/python-modules-setup.patch
	./configure CFLAGS="-static" CPPFLAGS="-static" LDFLAGS="-static" --prefix="$ROOTFS" \
		--disable-shared \
		--enable-optimizations
	make CFLAGS="-static" CPPFLAGS="-static" LDFLAGS="-static" LINKFORSHARED=" " -j"$NPROC"
	make install 2>/dev/null
	cd -
}

fixSymlinks() {
	# the ld-linux symlink is absolute.  Point to libc in current dir by relative path instead.
	cd "$ROOTFS"/toolchain/lib
	interp="ld-musl-$ARCH.so.1"
	rm "$interp"
	ln -s ./libc.so "$interp"
	cd -
}

### RUN

prepareDir
prepareMake
prepareToybox
prepareCoreutils
prepareDiffutils
prepareFindutils
prepareGawk
prepareGrep
prepareLinuxHeaders
prepareBison
prepareGzip
preparem4
prepareGperf
prepareAutoconf
preparePerl
prepareTexinfo
prepareXz
# prepareFlex
preparePatchelf
fixSymlinks
preparePython
