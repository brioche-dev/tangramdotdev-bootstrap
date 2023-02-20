# Directories
DIST=$(PWD)/dist
PATCHES=$(PWD)/patches
SCRIPTS=$(PWD)/scripts
SOURCES=$(PWD)/sources
WORK=$(PWD)/work

# Constants
DATE=$(shell date +"%Y%m%d")

# Build details
OCI=docker
CTNG_IMAGE_FILE=$(PWD)/ctng-dockerfile
IMAGE_FILE=$(PWD)/Dockerfile
CTNG_IMAGE_AMD64=ctng-amd64
CTNG_IMAGE_ARM64=ctng-arm64
IMAGE_AMD64=static-tools-amd64
IMAGE_ARM64=static-tools-arm64
VOLMOUNT=/bootstrap

# Static tools
# Some packages use a single installed binary to catalyze the build:
# cp: coreutils
# diff: diffutils
# find: findutils
BOOTSTRAP_TOOLS:=bash bison cp diff find flex gawk gperf grep gzip m4 make patch python3 sed tar xz
BOOTSTRAP_TOOLS_MACOS:=bash bison cp diff find flex gawk gperf grep gzip m4 patch sed tar

# Package versions
BASH_VER=5.1.16
BISON_VER=3.8.2
COREUTILS_VER=9.1
DIFFUTILS_VER=3.9
FINDUTILS_VER=4.9.0
FLEX_VER=2.6.4
GAWK_VER=5.2.1
GPERF_VER=3.1
GREP_VER=3.8
GZIP_VER=1.12
LINUX_VER=6.1.8
M4_VER=1.4.19
MAKE_VER=4.4
PATCH_VER=2.7.6
PATCHELF_VER=0.15.0
PCRE2_VER=10.42
PYTHON_VER=3.11.1
SED_VER=4.9
TAR_VER=1.34
TOYBOX_VER=0.8.9
XZ_VER=5.4.1

# Macos versions
CLANG_VER=15.0.7
CCTOOLS_VER=973.0.1
MACOS_SDK_VER=13.1
DARWIN_VER=22.0

# Interface targets

.PHONY: all
all: dist

.PHONY: clean
clean: clean_dist clean_bash clean_glibc_toolchain clean_macos_bootstrap clean_bootstrap_tools clean_toybox

.PHONY: clean_sources
clean_sources:
	rm -rfv $(SOURCES)/*

.PHONY: deps
deps: dirs images

.PHONY: dirs
dirs:
	mkdir -p $(DIST) $(SOURCES) $(WORK)

.PHONY: dist
dist: bash_dist glibc_toolchain_dist macos_bootstrap_dist musl_toolchain_dist bootstrap_tools_dist toybox_dist

.PHONY: images
images: image_amd64 image_arm64

# https://stackoverflow.com/a/26339924/7163088
.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

# Docker build environment

.PHONY: image_amd64
image_amd64:
	$(OCI) build --platform linux/amd64 -t $(IMAGE_AMD64) -f $(IMAGE_FILE) .

.PHONY: image_arm64
image_arm64:
	$(OCI) build --platform linux/arm64/v8 -t $(IMAGE_ARM64) -f $(IMAGE_FILE) .

.PHONY: ctng_image_amd64
ctng_image_amd64:
	$(OCI) build --platform linux/amd64 -t $(CTNG_IMAGE_AMD64) -f $(CTNG_IMAGE_FILE) .

.PHONY: ctng_image_arm64
ctng_image_arm64:
	$(OCI) build --platform linux/arm64/v8 -t $(CTNG_IMAGE_ARM64) -f $(CTNG_IMAGE_FILE) .

# GCC/GLIBC toolchain

.PHONY: glibc_toolchain
glibc_toolchain: glibc_toolchain_amd64 glibc_toolchain_arm64

.PHONY: glibc_toolchain_amd64
glibc_toolchain_amd64: $(WORK)/x86_64/glibc_toolchain

.PHONY: glibc_toolchain_arm64
glibc_toolchain_arm64: $(WORK)/aarch64/glibc_toolchain

.PHONY: clean_glibc_toolchain
clean_glibc_toolchain:
	rm -rfv $(WORK)/{aarch64,x86-64}/glibc_toolchain 

# Macos bootstrap
.PHONY: macos_bootstrap
macos_bootstrap: $(WORK)/macos_bootstrap

.PHONY: clean_macos_bootstrap
clean_macos_bootstrap:
	rm -rfv $(WORK)/macos_bootstrap

# Static tools

.PHONY: bootstrap_tools
bootstrap_tools: bootstrap_tools_amd64 bootstrap_tools_arm64 bootstrap_tools_macos

.PHONY: bootstrap_tools_amd64
bootstrap_tools_amd64: $(BOOTSTRAP_TOOLS:%=$(WORK)/x86_64/rootfs/bin/%)

.PHONY: bootstrap_tools_arm64
bootstrap_tools_arm64: $(BOOTSTRAP_TOOLS:%=$(WORK)/aarch64/rootfs/bin/%)

DIRNAME = "$()"
.PHONY: bootstrap_tools_macos
bootstrap_tools_macos: $(BOOTSTRAP_TOOLS_MACOS:%=$(WORK)/macos/rootfs/bin/%)
	echo "#!/bin/sh" > $(WORK)/macos/rootfs/bin/gunzip && \
	echo "exec \$$(dirname \$$0)/gzip -d \"\$$@\"" >> $(WORK)/macos/rootfs/bin/gunzip && \
	echo "#!/bin/sh" > $(WORK)/macos/rootfs/bin/egrep && \
	echo "exec \$$(dirname \$$0)/grep -E \"\$$@\"" >> $(WORK)/macos/rootfs/bin/egrep && \
	echo "#!/bin/sh" > $(WORK)/macos/rootfs/bin/fgrep && \
	echo "exec \$$(dirname \$$0)/grep -F \"\$$@\"" >> $(WORK)/macos/rootfs/bin/fgrep && \
	chmod +x $(WORK)/macos/rootfs/bin/{gunzip,egrep,fgrep} && \
	install_name_tool -add_rpath @executable_path/../lib $(WORK)/macos/rootfs/bin/grep || true

.PHONY: clean_bootstrap_tools
clean_bootstrap_tools:
	rm -rfv $(WORK)/{aarch64,x86_64,macos}

# Toybox

.PHONY: toybox
toybox: toybox_linux_amd64 toybox_linux_arm64 toybox_macos

.PHONY: toybox_linux_amd64
toybox_linux_amd64: $(WORK)/toybox_linux_aarch64

.PHONY: toybox_linux_arm64
toybox_linux_arm64: $(WORK)/toybox_linux_x86_64

.PHONY: toybox_macos
toybox_macos: $(WORK)/toybox_macos_universal

.PHONY: clean_toybox
clean_toybox:
	rm -rfv $(WORK)/toybox*

# Dist targets

.PHONY: bash_dist
bash_dist: $(DIST)/bash_static_arm64_linux.tar.zstd $(DIST)/bash_static_amd64_linux.tar.zstd $(DIST)/bash_macos.tar.zstd

.PHONY: glibc_toolchain_dist
glibc_toolchain_dist: glibc_toolchain_dist_amd64 glibc_toolchain_dist_arm64

.PHONY: glibc_toolchain_dist_amd64
glibc_toolchain_dist_amd64: $(DIST)/toolchain_amd64_linux_gnu.tar.xz

.PHONY: glibc_toolchain_dist_arm64
glibc_toolchain_dist_arm64: $(DIST)/toolchain_arm64_linux_gnu.tar.xz

.PHONY: musl_toolchain_dist
musl_toolchain_dist: $(DIST)/toolchain_arm64_linux_musl.tar.xz $(DIST)/toolchain_amd64_linux_musl.tar.xz

.PHONY: linux_headers_dist
linux_headers_dist: linux_headers_amd64_dist linux_headers_arm64_dist

.PHONY: linux_headers_amd64_dist
linux_headers_amd64_dist: $(DIST)/linux_headers_$(LINUX_VER)_amd64.tar.xz

.PHONY: linux_headers_arm64_dist
linux_headers_arm64_dist: $(DIST)/linux_headers_$(LINUX_VER)_arm64.tar.xz

.PHONY: bootstrap_tools_dist
bootstrap_tools_dist: bootstrap_tools_amd64_dist bootstrap_tools_arm64_dist bootstrap_tools_macos_dist

.PHONY: bootstrap_tools_amd64_dist
bootstrap_tools_amd64_dist: $(DIST)/bootstrap_tools_amd64_linux.tar.zstd 

.PHONY: bootstrap_tools_arm64_dist
bootstrap_tools_arm64_dist: $(DIST)/bootstrap_tools_arm64_linux.tar.zstd

.PHONY: bootstrap_tools_macos_dist
bootstrap_tools_macos_dist: $(DIST)/bootstrap_tools_macos.tar.xz

.PHONY: toybox_dist
toybox_dist: $(DIST)/toybox_arm64_linux.tar.zstd $(DIST)/toybox_amd64_linux.tar.zstd $(DIST)/toybox_macos.tar.zstd

.PHONY: clean_dist
clean_dist:
	rm -rfv $(DIST)/*

# Bootstrap tools individual targets

## bash

.PHONY: bash
bash: bash_linux_amd64 bash_linux_arm64 bash_macos

.PHONY: bash_linux_amd64
bash_linux_amd64: $(WORK)/bash_linux_x86_64

.PHONY: bash_linux_arm64
bash_linux_arm64: $(WORK)/bash_linux_aarch64

.PHONY: bash_macos
bash_macos: $(WORK)/bash_macos_universal

.PHONY: clean_bash
clean_bash:
	rm -rfv $(WORK)/bash* $(WORK)/aarch64/rootfs/bin/bash $(WORK)/x86_64/rootfs/bin/bash $(WORK)/macos/rootfs/bin/bash

## bison

.PHONY: bison
bison: bison_linux_amd64 bison_linux_arm64 bison_macos

.PHONY: bison_linux_amd64
bison_linux_amd64: $(WORK)/x86_64/rootfs/bin/bison

.PHONY: bison_linux_arm64
bison_linux_arm64: $(WORK)/aarch64/rootfs/bin/bison

# FIXME - bring yacc too
.PHONY: bison_macos
bison_macos: $(WORK)/macos/rootfs/bin/bison

.PHONY: clean_bison
clean_bison:
	rm -rfv $(WORK)/bison* $(WORK)/aarch64/rootfs/bin/bison $(WORK)/x86_64/rootfs/bin/bison $(WORK)/macos/rootfs/bin/bison

## coreutils

.PHONY: coreutils
coreutils: coreutils_linux_amd64 coreutils_linux_arm64 coreutils_macos

.PHONY: coreutils_linux_amd64
coreutils_linux_amd64: $(WORK)/x86_64/rootfs/bin/cp

.PHONY: coreutils_linux_arm64
coreutils_linux_arm64: $(WORK)/aarch64/rootfs/bin/cp

COREUTILS_BINS=base32 base64 b2sum basename basenc cat chcon chgrp chmod chown chroot cksum comm cp csplit cut date dd df dir dircolors dirname du echo env expand expr factor false fmt fold groups head hostid id install join link ln logname ls md5sum mkdir mkfifo mknod mktemp mv nice nl nohup nproc numfmt od paste pathchk pinky pr printenv printf ptx pwd readlink realpath rm rmdir runcon seq sha1sum sha224sum sha256sum sha384sum sha512sum shred shuf sleep sort split stat stty sum sync tac tail tee test timeout touch tr true truncate tsort tty uname unexpand uniq unlink users vdir wc who whoami yes
.PHONY: coreutils_macos
coreutils_macos: $(COREUTILS_BINS:%=$(WORK)/macos/rootfs/bin/%)

.PHONY: clean_coreutils
clean_coreutils:
	rm -rfv $(WORK)/coreutils* $(WORK)/aarch64/rootfs/bin/cp $(WORK)/x86_64/rootfs/bin/cp  $(COREUTILS_BINS:%=$(WORK)/macos/rootfs/bin/%)

## diffutils

.PHONY: diffutils
diffutils: diffutils_linux_amd64 diffutils_linux_arm64

.PHONY: diffutils_linux_amd64
diffutils_linux_amd64: $(WORK)/x86_64/rootfs/bin/diff

.PHONY: diffutils_linux_arm64
diffutils_linux_arm64: $(WORK)/aarch64/rootfs/bin/diff

DIFFUTILS_BINS=cmp diff diff3 sdiff
.PHONY: diffutils_macos
diffutils_macos: $(DIFFUTILS_BINS:%=$(WORK)/macos/rootfs/bin/%)

.PHONY: clean_diffutils
clean_diffutils:
	rm -rfv $(WORK)/diffutils* $(WORK)/aarch64/rootfs/bin/diff $(WORK)/x86_64/rootfs/bin/diff $(DIFFUTILS_BINS:%=$(WORK)/macos/rootfs/bin/%)

## findutils

.PHONY: findutils
findutils: findutils_linux_amd64 findutils_linux_arm64

.PHONY: findutils_linux_amd64
findutils_linux_amd64: $(WORK)/x86_64/rootfs/bin/find

.PHONY: findutils_linux_arm64
findutils_linux_arm64: $(WORK)/aarch64/rootfs/bin/find

FINDUTILS_BINS=find locate xargs
.PHONY: findutils_macos
findutils_macos: $(FINDUTILS_BINS:%=$(WORK)/macos/rootfs/bin/%)

.PHONY: clean_findutils
clean_findutils:
	rm -rfv $(WORK)/findutils* $(WORK)/aarch64/rootfs/bin/find $(WORK)/x86_64/rootfs/bin/find $(FINDUTILS_BINS:%=$(WORK)/macos/rootfs/bin/%)

## flex

.PHONY: flex
flex: flex_linux_amd64 flex_linux_arm64

.PHONY: flex_linux_amd64
flex_linux_amd64: $(WORK)/x86_64/rootfs/bin/flex

.PHONY: flex_linux_arm64
flex_linux_arm64: $(WORK)/aarch64/rootfs/bin/flex

FLEX_BINS=flex flex++
.PHONY: flex_macos
flex_macos: $(FLEX_BINS:%=$(WORK)/macos/rootfs/bin/%)

.PHONY: clean_flex
clean_flex:
	rm -rfv $(WORK)/flex* $(WORK)/aarch64/rootfs/bin/flex $(WORK)/x86_64/rootfs/bin/flex $(FLEX_BINS:%=$(WORK)/macos/rootfs/bin/%)

## gawk

.PHONY: gawk
gawk: gawk_linux_amd64 gawk_linux_arm64

.PHONY: gawk_linux_amd64
gawk_linux_amd64: $(WORK)/x86_64/rootfs/bin/gawk

.PHONY: gawk_linux_arm64
gawk_linux_arm64: $(WORK)/aarch64/rootfs/bin/gawk

# FIXME - add symlink awk -> gawk
.PHONY: gawk_macos
gawk_macos: $(WORK)/macos/rootfs/bin/gawk

.PHONY: clean_gawk
clean_gawk:
	rm -rfv $(WORK)/gawk* $(WORK)/aarch64/rootfs/bin/gawk $(WORK)/x86_64/rootfs/bin/gawk $(WORK)/macos/rootfs/bin/gawk

## gperf

.PHONY: gperf
gperf: gperf_linux_amd64 gperf_linux_arm64

.PHONY: gperf_linux_amd64
gperf_linux_amd64: $(WORK)/x86_64/rootfs/bin/gperf

.PHONY: gperf_linux_arm64
gperf_linux_arm64: $(WORK)/aarch64/rootfs/bin/gperf

.PHONY: gperf_macos
gperf_macos: $(WORK)/macos/rootfs/bin/gperf

.PHONY: clean_gperf
clean_gperf:
	rm -rfv $(WORK)/gperf* $(WORK)/aarch64/rootfs/bin/gperf $(WORK)/x86_64/rootfs/bin/gperf $(WORK)/macos/rootfs/bin/gperf

## grep

.PHONY: grep
grep: grep_linux_amd64 grep_linux_arm64

.PHONY: grep_linux_amd64
grep_linux_amd64: $(WORK)/x86_64/rootfs/bin/grep

.PHONY: grep_linux_arm64
grep_linux_arm64: $(WORK)/aarch64/rootfs/bin/grep

.PHONY: grep_macos
grep_macos: pcre_macos $(WORK)/macos/rootfs/bin/grep

.PHONY: clean_grep
clean_grep:
	rm -rfv $(WORK)/grep* $(WORK)/aarch64/rootfs/bin/grep $(WORK)/x86_64/rootfs/bin/grep $(WORK)/macos/rootfs/bin/grep

.PHONY: pcre_macos
pcre_macos: $(WORK)/macos/rootfs/lib/libpcre2-8.0.dylib

## gzip

.PHONY: gzip
gzip: gzip_linux_amd64 gzip_linux_arm64

.PHONY: gzip_linux_amd64
gzip_linux_amd64: $(WORK)/x86_64/rootfs/bin/gzip

.PHONY: gzip_linux_arm64
gzip_linux_arm64: $(WORK)/aarch64/rootfs/bin/gzip

.PHONY: gzip_macos
gzip_macos: $(WORK)/macos/rootfs/bin/gzip

.PHONY: clean_gzip
clean_gzip:
	rm -rfv $(WORK)/gzip* $(WORK)/aarch64/rootfs/bin/gzip $(WORK)/x86_64/rootfs/bin/gzip $(WORK)/macos/rootfs/bin/gzip

## gzip

.PHONY: help2man
help2man: help2man_linux_amd64 help2man_linux_arm64

.PHONY: help2man_linux_amd64
help2man_linux_amd64: $(WORK)/x86_64/rootfs/bin/help2man

.PHONY: help2man_linux_arm64
help2man_linux_arm64: $(WORK)/aarch64/rootfs/bin/help2man

.PHONY: clean_help2man
clean_help2man:
	rm -rfv $(WORK)/help2man* $(WORK)/aarch64/rootfs/bin/help2man $(WORK)/x86_64/rootfs/bin/help2man

## m4

.PHONY: m4
m4: m4_linux_amd64 m4_linux_arm64

.PHONY: m4_linux_amd64
m4_linux_amd64: $(WORK)/x86_64/rootfs/bin/m4

.PHONY: m4_linux_arm64
m4_linux_arm64: $(WORK)/aarch64/rootfs/bin/m4

.PHONY: m4_macos
m4_macos: $(WORK)/macos/rootfs/bin/m4

.PHONY: clean_m4
clean_m4:
	rm -rfv $(WORK)/m4* $(WORK)/aarch64/rootfs/bin/m4 $(WORK)/x86_64/rootfs/bin/m4 $(WORK)/macos/rootfs/bin/m4

## make

.PHONY: make
make: make_linux_amd64 make_linux_arm64

.PHONY: make_linux_amd64
make_linux_amd64: $(WORK)/x86_64/rootfs/bin/make

.PHONY: make_linux_arm64
make_linux_arm64: $(WORK)/aarch64/rootfs/bin/make

# FIXME - building for macOS-x86_64 but attempting to link with file built for macOS-arm64
.PHONY: make_macos
make_macos: $(WORK)/macos/rootfs/bin/make

.PHONY: clean_make
clean_make:
	rm -rfv $(WORK)/make* $(WORK)/aarch64/rootfs/bin/make $(WORK)/x86_64/rootfs/bin/make $(WORK)/macos/rootfs/bin/make

## Linux headers

.PHONY: linux_headers
linux_headers: linux_headers_amd64 linux_headers_arm64

.PHONY: linux_headers_amd64
linux_headers_amd64: $(WORK)/x86_64/linux_headers

.PHONY: linux_headers_arm64
linux_headers_arm64: $(WORK)/aarch64/linux_headers

.PHONY: clean_linux_headers
clean_linux_headers:
	rm -rfv $(WORK)/x86_64/linux* $(WORK)/aarch64/linux*

## musl

.PHONY: musl
glibc: musl_linux_amd64 musl_linux_arm64

.PHONY: musl_linux_amd64
msul_linux_amd64: $(WORK)/x86_64/rootfs/lib/ld-musl-x86_64.so.1

.PHONY: musl_linux_arm64
musl_linux_arm64: $(WORK)/aarch64/rootfs/lib/ld-musl-aarch64.so.1

.PHONY: clean_musl
clean_musl:
	rm -rfv $(WORK)/musl* $(WORK)/aarch64/rootfs/lib/ld-musl-aarch64.so.1 $(WORK)/x86_64/rootfs/lib/ld-musl-x86_64.so.1

## patch

.PHONY: patch
patch: patch_linux_amd64 patch_linux_arm64

.PHONY: patch_linux_amd64
patch_linux_amd64: $(WORK)/x86_64/rootfs/bin/patch

.PHONY: patch_linux_arm64
patch_linux_arm64: $(WORK)/aarch64/rootfs/bin/patch

.PHONY: patch_macos
patch_macos: $(WORK)/macos/rootfs/bin/patch

.PHONY: clean_patch
clean_patch:
	rm -rfv $(WORK)/patch* $(WORK)/aarch64/rootfs/bin/patch $(WORK)/x86_64/rootfs/bin/patch $(WORK)/macos/rootfs/bin/patch

## patchelf

.PHONY: patchelf
patchelf: patchelf_linux_amd64 patchelf_linux_arm64

.PHONY: patchelf_linux_amd64
patchelf_linux_amd64: $(WORK)/x86_64/rootfs/bin/patchelf

.PHONY: patchelf_linux_arm64
patchelf_linux_arm64: $(WORK)/aarch64/rootfs/bin/patchelf

.PHONY: clean_patchelf
clean_patchelf:
	rm -rfv $(WORK)/patchelf* $(WORK)/aarch64/rootfs/bin/patchelf $(WORK)/x86_64/rootfs/bin/patchelf

## python

.PHONY: python
python: python_linux_amd64 python_linux_arm64

.PHONY: python_linux_amd64
python_linux_amd64: $(WORK)/x86_64/rootfs/bin/python3

.PHONY: python_linux_arm64
python_linux_arm64: $(WORK)/aarch64/rootfs/bin/python3

.PHONY: clean_python
clean_python:
	rm -rfv $(WORK)/python* $(WORK)/aarch64/rootfs/bin/python3 $(WORK)/x86_64/rootfs/bin/python3

## sed

.PHONY: sed
sed: sed_linux_amd64 sed_linux_arm64

.PHONY: sed_linux_amd64
sed_linux_amd64: $(WORK)/x86_64/rootfs/bin/sed

.PHONY: sed_linux_arm64
sed_linux_arm64: $(WORK)/aarch64/rootfs/bin/sed

.PHONY: sed_macos
sed_macos: $(WORK)/macos/rootfs/bin/sed

.PHONY: clean_sed
clean_sed:
	rm -rfv $(WORK)/sed* $(WORK)/aarch64/rootfs/bin/sed $(WORK)/x86_64/rootfs/bin/sed $(WORK)/macos/rootfs/bin/sed

## tar

.PHONY: tar
tar: tar_linux_amd64 tar_linux_arm64

.PHONY: tar_linux_amd64
tar_linux_amd64: $(WORK)/x86_64/rootfs/bin/tar

.PHONY: tar_linux_arm64
tar_linux_arm64: $(WORK)/aarch64/rootfs/bin/tar

.PHONY: tar_macos
tar_macos: $(WORK)/macos/rootfs/bin/tar

.PHONY: clean_tar
clean_tar:
	rm -rfv $(WORK)/tar* $(WORK)/aarch64/rootfs/bin/tar $(WORK)/x86_64/rootfs/bin/tar $(WORK)/macos/rootfs/bin/tar

## xz

.PHONY: xz
xz: xz_linux_amd64 xz_linux_arm64

.PHONY: xz_linux_amd64
xz_linux_amd64: $(WORK)/x86_64/rootfs/bin/xz

.PHONY: xz_linux_arm64
xz_linux_arm64: $(WORK)/aarch64/rootfs/bin/xz

.PHONY: clean_xz
clean_xz:
	rm -rfv $(WORK)/xz* $(WORK)/aarch64/rootfs/bin/xz $(WORK)/x86_64/rootfs/bin/xz

# Work targets

## glibc toolchain

$(WORK)/amd64/glibc_toolchain:
	$(OCI) run \
		--rm \
		-it \
		--name "glibc_toolchain_amd64" \
		--platform linux/amd64 \
		-v "$(PWD)":$(VOLMOUNT) \
		$(CTNG_IMAGE_AMD64) \
		/bin/bash -c $(VOLMOUNT)/scripts/build_ctng_toolchain.sh

$(WORK)/arm64/glibc_toolchain:
	$(OCI) run \
		--rm \
		-it \
		--name "glibc_toolchain_arm64" \
		--platform linux/arm64 \
		-v "$(PWD)":$(VOLMOUNT) \
		$(CTNG_IMAGE_ARM64) \
		/bin/bash -c $(VOLMOUNT)/scripts/build_ctng_toolchain.sh

$(DIST)/toolchain_%_linux_gnu.tar.xz: $(WORK)/%/glibc_toolchain
	tar -C $< -cJf $@ .

## Bash

$(DIST)/bash_static_arm64_linux.tar.zstd: $(WORK)/aarch64/rootfs/bin/bash
	$(SCRIPTS)/build_binary_artifact.sh $< $@ bash

$(DIST)/bash_static_amd64_linux.tar.zstd: $(WORK)/x86_64/rootfs/bin/bash
	$(SCRIPTS)/build_binary_artifact.sh $< $@ bash

$(DIST)/bash_macos.tar.zstd: $(WORK)/bash_macos_universal
	$(SCRIPTS)/build_binary_artifact.sh $< $@ bash

$(WORK)/x86_64/rootfs/bin/bash: $(WORK)/bash-$(BASH_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_bash.sh $(BASH_VER)

$(WORK)/aarch64/rootfs/bin/bash: $(WORK)/bash-$(BASH_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_bash.sh $(BASH_VER)

$(WORK)/bash_linux_%: $(WORK)/%/rootfs/bin/bash
	cp $< $@

$(WORK)/bash_macos_universal: $(WORK)/macos/rootfs/bin/bash
	cp $< $@

$(WORK)/macos/arm64/rootfs/bin/bash: $(WORK)/bash-$(BASH_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

$(WORK)/macos/x86_64/rootfs/bin/bash: $(WORK)/bash-$(BASH_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

## general macos

$(WORK)/macos/rootfs/bin/%: $(WORK)/macos/arm64/rootfs/bin/% $(WORK)/macos/x86_64/rootfs/bin/%
	mkdir -p $(dir $@) && lipo -create -output $@ $^

## Bison

$(WORK)/x86_64/rootfs/bin/bison: $(WORK)/bison-$(BISON_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_bison.sh $(BISON_VER)

$(WORK)/aarch64/rootfs/bin/bison: $(WORK)/bison-$(BISON_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_bison.sh $(BISON_VER)

$(WORK)/macos/arm64/rootfs/bin/bison: $(WORK)/bison-$(BISON_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

$(WORK)/macos/x86_64/rootfs/bin/bison: $(WORK)/bison-$(BISON_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

## Coreutils

$(WORK)/x86_64/rootfs/bin/cp: $(WORK)/coreutils-$(COREUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_coreutils.sh $(COREUTILS_VER)

$(WORK)/aarch64/rootfs/bin/cp: $(WORK)/coreutils-$(COREUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_coreutils.sh $(COREUTILS_VER)

$(COREUTILS_BINS:%=$(WORK)/macos/x86_64/rootfs/bin/%): $(WORK)/coreutils-$(COREUTILS_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(COREUTILS_BINS:%=$(WORK)/macos/arm64/rootfs/bin/%): $(WORK)/coreutils-$(COREUTILS_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## Diffutils

$(WORK)/x86_64/rootfs/bin/diff: $(WORK)/diffutils-$(DIFFUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_diffutils.sh $(DIFFUTILS_VER)

$(WORK)/aarch64/rootfs/bin/diff: $(WORK)/diffutils-$(DIFFUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_diffutils.sh $(DIFFUTILS_VER)

$(DIFFUTILS_BINS:%=$(WORK)/macos/x86_64/rootfs/bin/%): $(WORK)/diffutils-$(DIFFUTILS_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(DIFFUTILS_BINS:%=$(WORK)/macos/arm64/rootfs/bin/%): $(WORK)/diffutils-$(DIFFUTILS_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## Findutils

$(WORK)/x86_64/rootfs/bin/find: $(WORK)/findutils-$(FINDUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_findutils.sh $(FINDUTILS_VER)

$(WORK)/aarch64/rootfs/bin/find: $(WORK)/findutils-$(FINDUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_findutils.sh $(FINDUTILS_VER)

$(FINDUTILS_BINS:%=$(WORK)/macos/x86_64/rootfs/bin/%): $(WORK)/findutils-$(FINDUTILS_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(FINDUTILS_BINS:%=$(WORK)/macos/arm64/rootfs/bin/%): $(WORK)/findutils-$(FINDUTILS_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## Flex

$(WORK)/x86_64/rootfs/bin/flex: $(WORK)/flex-$(FLEX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_flex.sh $(FLEX_VER)

$(WORK)/aarch64/rootfs/bin/flex: $(WORK)/flex-$(FLEX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_flex.sh $(FLEX_VER)

$(FLEX_BINS:%=$(WORK)/macos/x86_64/rootfs/bin/%): $(WORK)/flex-$(FLEX_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(FLEX_BINS:%=$(WORK)/macos/arm64/rootfs/bin/%): $(WORK)/flex-$(FLEX_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## Gawk

$(WORK)/x86_64/rootfs/bin/gawk: $(WORK)/gawk-$(GAWK_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_gawk.sh $(GAWK_VER)

$(WORK)/aarch64/rootfs/bin/gawk: $(WORK)/gawk-$(GAWK_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_gawk.sh $(GAWK_VER)

$(WORK)/macos/x86_64/rootfs/bin/gawk: $(WORK)/gawk-$(GAWK_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/gawk: $(WORK)/gawk-$(GAWK_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

# NOTE - gawk builds a fat binary on arm already
$(WORK)/macos/rootfs/bin/gawk: $(WORK)/macos/arm64/rootfs/bin/gawk
	cp $< $@ && \
	cd $(WORK)/macos/rootfs/bin && \
	ln -s gawk awk && \
	cd -

## Gperf

$(WORK)/x86_64/rootfs/bin/gperf: $(WORK)/gperf-$(GPERF_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_gperf.sh $(GPERF_VER)

$(WORK)/aarch64/rootfs/bin/gperf: $(WORK)/gperf-$(GPERF_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_gperf.sh $(GPERF_VER)

$(WORK)/macos/x86_64/rootfs/bin/gperf: $(WORK)/gperf-$(GPERF_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/gperf: $(WORK)/gperf-$(GPERF_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## Grep

$(WORK)/x86_64/rootfs/bin/grep: $(WORK)/grep-$(GREP_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_grep.sh $(GREP_VER)

$(WORK)/aarch64/rootfs/bin/grep: $(WORK)/grep-$(GREP_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_grep.sh $(GREP_VER)

$(WORK)/macos/x86_64/rootfs/bin/grep: $(WORK)/grep-$(GREP_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/grep: $(WORK)/grep-$(GREP_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

$(WORK)/macos/arm64/rootfs/lib/libpcre2-8.0.dylib: $(WORK)/pcre2-$(PCRE2_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64

$(WORK)/macos/x86_64/rootfs/lib/libpcre2-8.0.dylib: $(WORK)/pcre2-$(PCRE2_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64

$(WORK)/macos/rootfs/lib/libpcre2-8.0.dylib: $(WORK)/macos/x86_64/rootfs/lib/libpcre2-8.0.dylib $(WORK)/macos/arm64/rootfs/lib/libpcre2-8.0.dylib
	lipo -create -output $@ $^

## Gzip

$(WORK)/x86_64/rootfs/bin/gzip: $(WORK)/gzip-$(GZIP_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_gzip.sh $(GZIP_VER)

$(WORK)/aarch64/rootfs/bin/gzip: $(WORK)/gzip-$(GZIP_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_gzip.sh $(GZIP_VER)

$(WORK)/macos/x86_64/rootfs/bin/gzip: $(WORK)/gzip-$(GZIP_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/gzip: $(WORK)/gzip-$(GZIP_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## M4

$(WORK)/x86_64/rootfs/bin/m4: $(WORK)/m4-$(M4_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_m4.sh $(M4_VER)

$(WORK)/aarch64/rootfs/bin/m4: $(WORK)/m4-$(M4_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_m4.sh $(M4_VER)

$(WORK)/macos/x86_64/rootfs/bin/m4: $(WORK)/m4-$(M4_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/m4: $(WORK)/m4-$(M4_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## Make

$(WORK)/x86_64/rootfs/bin/make: $(WORK)/make-$(MAKE_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_make.sh $(MAKE_VER)

$(WORK)/aarch64/rootfs/bin/make: $(WORK)/make-$(MAKE_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_make.sh $(MAKE_VER)

$(WORK)/macos/x86_64/rootfs/bin/make: $(WORK)/make-$(MAKE_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/make: $(WORK)/make-$(MAKE_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## musl

$(WORK)/x86_64/rootfs/lib/ld-musl-x86_64.so.1: $(WORK)/musl-$(MUSL_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_musl.sh $(MUSL_VER)

$(WORK)/aarch64/rootfs/lib/ld-musl-aarch64.so.1: $(WORK)/musl-$(MUSL_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_musl.sh $(MUSL_VER)

## patch

$(WORK)/x86_64/rootfs/bin/patch: $(WORK)/patch-$(PATCH_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_patch.sh $(PATCH_VER)

$(WORK)/aarch64/rootfs/bin/patch: $(WORK)/patch-$(PATCH_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_patch.sh $(PATCH_VER)

$(WORK)/macos/x86_64/rootfs/bin/patch: $(WORK)/patch-$(PATCH_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/patch: $(WORK)/patch-$(PATCH_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## patchelf

$(WORK)/x86_64/rootfs/bin/patchelf: $(WORK)/patchelf-$(PATCHELF_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_patchelf.sh $(PATCHELF_VER)

$(WORK)/aarch64/rootfs/bin/patchelf: $(WORK)/patchelf-$(PATCHELF_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_patchelf.sh $(PATCHELF_VER)

## Python

$(WORK)/x86_64/rootfs/bin/python3: $(WORK)/Python-$(PYTHON_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_python.sh $(PYTHON_VER)

$(WORK)/aarch64/rootfs/bin/python3: $(WORK)/Python-$(PYTHON_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_python.sh $(PYTHON_VER)

## sed

$(WORK)/x86_64/rootfs/bin/sed: $(WORK)/sed-$(SED_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_sed.sh $(SED_VER)

$(WORK)/aarch64/rootfs/bin/sed: $(WORK)/sed-$(SED_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_sed.sh $(SED_VER)

$(WORK)/macos/x86_64/rootfs/bin/sed: $(WORK)/sed-$(SED_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/sed: $(WORK)/sed-$(SED_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## tar

$(WORK)/x86_64/rootfs/bin/tar: $(WORK)/tar-$(TAR_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_tar.sh $(TAR_VER)

$(WORK)/aarch64/rootfs/bin/tar: $(WORK)/tar-$(TAR_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_tar.sh $(TAR_VER)

$(WORK)/macos/x86_64/rootfs/bin/tar: $(WORK)/tar-$(TAR_VER)
	$(SCRIPTS)/run_macos_build.sh $< x86_64 && strip $@

$(WORK)/macos/arm64/rootfs/bin/tar: $(WORK)/tar-$(TAR_VER)
	$(SCRIPTS)/run_macos_build.sh $< arm64 && strip $@

## xz

$(WORK)/x86_64/rootfs/bin/xz: $(WORK)/xz-$(XZ_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_static_xz.sh $(XZ_VER)

$(WORK)/aarch64/rootfs/bin/xz: $(WORK)/xz-$(XZ_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_static_xz.sh $(XZ_VER)

## Macos toolchain

.PHONY: macos_sdk_dist
macos_sdk_dist: $(DIST)/macos_sdk$(MACOS_SDK_VER).tar.zstd

.PHONY: macos_sdk
macos_sdk: $(WORK)/macos_sdk$(MACOS_SDK_VER).sdk

$(DIST)/macos_sdk$(MACOS_SDK_VER).tar.zstd: $(WORK)/macos_sdk$(MACOS_SDK_VER).sdk
	tar -C $< --zstd -cf $@ .

CLI_TOOLS_PATH = /Library/Developer/CommandLineTools
$(WORK)/macos_sdk$(MACOS_SDK_VER).sdk:
	mkdir -p $@
	cp -R $(CLI_TOOLS_PATH)/SDKs/MacOSX$(MACOS_SDK_VER).sdk/* $@

.PHONY: macos_toolchain_dist
macos_toolchain_dist: $(DIST)/toolchain_macos.tar.zstd

.PHONY: macos_toolchain
macos_toolchain: $(WORK)/toolchain_macos

$(WORK)/toolchain_macos:
	mkdir -p $@ && \
	cp -R $(CLI_TOOLS_PATH)/usr $@ && \
	cp -R $(CLI_TOOLS_PATH)/Library $@ && \
	rm -rf $@/usr/{bin,lib}/swift*

$(DIST)/toolchain_macos.tar.zstd: $(WORK)/toolchain_macos
	tar -C $< --zstd -cf $@ .

## Musl toolchain

$(DIST)/toolchain_%_linux_musl.tar.xz: $(WORK)/toolchain_%_linux_musl.tar.xz
	cp $< $@ 

$(WORK)/toolchain_arm64_linux_musl.tar.xz: $(SOURCES)/aarch64-linux-musl-native.tgz
	$(SCRIPTS)/fix_musl_toolchain_symlink.sh $< $@ aarch64

$(WORK)/toolchain_amd64_linux_musl.tar.xz: $(SOURCES)/x86_64-linux-musl-native.tgz
	$(SCRIPTS)/fix_musl_toolchain_symlink.sh $< $@ x86_64

## Linux API Headers

$(DIST)/linux_headers_$(LINUX_VER)_%.tar.xz: $(WORK)/%/linux_headers
	tar -C $< -cJf $@ .

$(WORK)/x86_64/linux_headers: $(WORK)/x86_64/linux-$(LINUX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_headers.sh $(LINUX_VER)	

$(WORK)/aarch64/linux_headers: $(WORK)/aarch64/linux-$(LINUX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_headers.sh $(LINUX_VER)	

## Toybox

$(DIST)/toybox_arm64_linux.tar.zstd: $(WORK)/toybox_linux_aarch64
	$(SCRIPTS)/build_binary_artifact.sh $< $@ toybox

$(DIST)/toybox_amd64_linux.tar.zstd: $(WORK)/toybox_linux_x86_64
	$(SCRIPTS)/build_binary_artifact.sh $< $@ toybox

$(DIST)/toybox_macos.tar.zstd: $(WORK)/toybox_macos_universal
	$(SCRIPTS)/build_binary_artifact.sh $< $@ toybox

$(WORK)/toybox_linux_%: $(SOURCES)/toybox-%
	cp $< $@ && \
	chmod +x $@

$(WORK)/toybox_macos_universal: $(WORK)/toybox_macos_arm $(WORK)/toybox_macos_x86
	lipo -create -output $@ $^

$(WORK)/toybox_macos_arm:
	cd $(WORK) && \
	rm -rf $(WORK)/toybox-$(TOYBOX_VER) && \
	tar -xf $(SOURCES)/toybox-$(TOYBOX_VER).tar.gz && \
	cd toybox-$(TOYBOX_VER) && \
	rm -rf toybox; \
	CFLAGS="-target arm64-apple-macos12.3" make macos_defconfig toybox && \
	mv toybox $@

$(WORK)/toybox_macos_x86:
	cd $(WORK) && \
	rm -rf $(WORK)/toybox-$(TOYBOX_VER) && \
	tar -xf $(SOURCES)/toybox-$(TOYBOX_VER).tar.gz && \
	cd toybox-$(TOYBOX_VER) && \
	rm -rf toybox; \
	CFLAGS="-target x86_64-apple-macos12.3" make macos_defconfig toybox && \
	mv toybox $@

## Bootstrap Tools

$(DIST)/bootstrap_tools_arm64_linux.tar.zstd: bootstrap_tools_arm64
	tar -C $(WORK)/aarch64/rootfs --zstd -cf $@ .

$(DIST)/bootstrap_tools_amd64_linux.tar.zstd: bootstrap_tools_amd64
	tar -C $(WORK)/x86_64/rootfs --zstd -cf $@ .

$(DIST)/bootstrap_tools_macos.tar.xz: bootstrap_tools_macos
	cp -nR $(WORK)/macos/arm64/rootfs/{include,lib,libexec,share,var} $(WORK)/macos/rootfs && \
	cd $(WORK)/macos/rootfs/bin && \
	ln -s bash sh && \
	cd - && \
	tar -C $(WORK)/macos/rootfs -cJf $@ .

# Sources

$(WORK)/%: $(SOURCES)/%.tar.bz2
	cd $(WORK) && \
	tar -xf $<

$(WORK)/%: $(SOURCES)/%.tar.gz
	cd $(WORK) && \
	tar -xf $<

$(WORK)/%: $(SOURCES)/%.tar.lz
	cd $(WORK) && \
	tar -xf $<

$(WORK)/%: $(SOURCES)/%.tar.xz
	cd $(WORK) && \
	tar -xf $<

$(WORK)/x86_64/linux-$(LINUX_VER): $(SOURCES)/linux-$(LINUX_VER).tar.xz
	mkdir -p $(WORK)/x86_64 && \
	cd $(WORK)/x86_64 && \
	tar -xf $<

$(WORK)/aarch64/linux-$(LINUX_VER): $(SOURCES)/linux-$(LINUX_VER).tar.xz
	mkdir -p $(WORK)/aarch64 && \
	cd $(WORK)/aarch64 && \
	tar -xf $<

$(SOURCES)/bash-$(BASH_VER).tar.gz:
	wget -O $@ https://ftp.gnu.org/gnu/bash/bash-$(BASH_VER).tar.gz
	
$(SOURCES)/bison-$(BISON_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/bison/bison-$(BISON_VER).tar.xz

$(SOURCES)/coreutils-$(COREUTILS_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_VER).tar.xz

$(SOURCES)/diffutils-$(DIFFUTILS_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/diffutils/diffutils-$(DIFFUTILS_VER).tar.xz

$(SOURCES)/findutils-$(FINDUTILS_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/findutils/findutils-$(FINDUTILS_VER).tar.xz

$(SOURCES)/flex-$(FLEX_VER).tar.gz:
	wget -O $@ https://github.com/westes/flex/releases/download/v$(FLEX_VER)/flex-$(FLEX_VER).tar.gz

$(SOURCES)/gawk-$(GAWK_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/gawk/gawk-$(GAWK_VER).tar.xz

$(SOURCES)/gperf-$(GPERF_VER).tar.gz:
	wget -O $@ https://ftp.gnu.org/gnu/gperf/gperf-$(GPERF_VER).tar.gz

$(SOURCES)/grep-$(GREP_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/grep/grep-$(GREP_VER).tar.xz

$(SOURCES)/gzip-$(GZIP_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/gzip/gzip-$(GZIP_VER).tar.xz

$(SOURCES)/help2man-$(HELP2MAN_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/help2man/help2man-$(HELP2MAN_VER).tar.xz

$(SOURCES)/linux-$(LINUX_VER).tar.xz:
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VER).tar.xz

$(SOURCES)/make-$(MAKE_VER).tar.lz:
	wget -O $@ https://ftp.gnu.org/gnu/make/make-$(MAKE_VER).tar.lz

$(SOURCES)/m4-$(M4_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/m4/m4-$(M4_VER).tar.xz

$(SOURCES)/musl-$(MUSL_VER).tar.xz:
	wget -O $@ https://musl.libc.org/releases/musl-$(MUSL_VER).tar.gz

$(SOURCES)/patch-$(PATCH_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/patch/patch-$(PATCH_VER).tar.xz

$(SOURCES)/patchelf-$(PATCHELF_VER).tar.bz2:
	wget -O $@ https://github.com/NixOS/patchelf/releases/download/$(PATCHELF_VER)/patchelf-$(PATCHELF_VER).tar.bz2

$(SOURCES)/pcre2-$(PCRE2_VER).tar.bz2:
	wget -O $@ https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$(PCRE2_VER)/pcre2-$(PCRE2_VER).tar.bz2

$(SOURCES)/Python-$(PYTHON_VER).tar.xz:
	wget -O $@ https://www.python.org/ftp/python/$(PYTHON_VER)/Python-$(PYTHON_VER).tar.xz

$(WORK)/Python-$(PYTHON_VER): $(SOURCES)/Python-$(PYTHON_VER).tar.xz
	cd $(WORK) && \
	tar -xf $< && \
	cd $@ && \
	patch -p1 -i $(PATCHES)/python-modules-setup.patch

$(SOURCES)/sed-$(SED_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/sed/sed-$(SED_VER).tar.xz

$(SOURCES)/tar-$(TAR_VER).tar.xz:
	wget -O $@ https://ftp.gnu.org/gnu/tar/tar-$(TAR_VER).tar.xz

$(SOURCES)/xz-$(XZ_VER).tar.xz:
	wget -O $@ https://tukaani.org/xz/xz-$(XZ_VER).tar.xz

$(SOURCES)/aarch64-linux-musl-native.tgz:
	wget -O $@ https://musl.cc/aarch64-linux-musl-native.tgz

$(SOURCES)/x86_64-linux-musl-native.tgz:
	wget -O $@ https://musl.cc/x86_64-linux-musl-native.tgz

$(SOURCES)/toybox-$(TOYBOX_VER).tar.gz:
	wget -O $@ http://landley.net/toybox/downloads/toybox-$(TOYBOX_VER).tar.gz

$(SOURCES)/toybox-aarch64:
	wget -O $@ http://landley.net/toybox/downloads/binaries/$(TOYBOX_VER)/toybox-aarch64

$(SOURCES)/toybox-x86_64:
	wget -O $@ http://landley.net/toybox/downloads/binaries/$(TOYBOX_VER)/toybox-x86_64