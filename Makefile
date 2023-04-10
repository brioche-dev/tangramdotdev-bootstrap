# Constants
OCI=docker
IMAGE_FILE=$(PWD)/Dockerfile
IMAGE_AMD64=static-tools-amd64
IMAGE_ARM64=static-tools-arm64
VOLMOUNT=/bootstrap

# Directories
DIST=$(PWD)/dist
SCRIPTS=$(PWD)/scripts
SOURCES=$(PWD)/sources
WORK=$(PWD)/work

# Package versions
BUSYBOX_VER=1.36.0
COREUTILS_VER=9.2
DASH_VER=0.5.12
LINUX_VER=6.2.8
MACOS_SDK_VER=13.3

# Interface targets

.PHONY: all
all: busybox_linux_amd64 busybox_linux_arm64 dash_linux_amd64 dash_linux_arm64 env_linux_amd64 env_linux_arm64 linux_headers_amd64 linux_headers_arm64 macos_toolchain macos_sdk musl_cc_linux_amd64 musl_cc_linux_arm64

.PHONY: clean
clean: clean_dist
	rm -rfv $(WORK)/*

.PHONY: clean_all
clean_all: clean clean_sources

.PHONY: clean_dist
clean_dist:
	rm -rfv $(DIST)/*

.PHONY: clean_sources
clean_sources:
	rm -rfv $(SOURCES)/*

.PHONY: dirs
dirs:
	mkdir -p $(DIST) $(SOURCES) $(WORK)

# https://stackoverflow.com/a/26339924/7163088
.PHONY: list
list:
	@LC_ALL=C $(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/(^|\n)# Files(\n|$$)/,/(^|\n)# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

# Docker build environment, used to produce Linux API headers.

.PHONY: images
images: image_amd64 image_arm64

.PHONY: image_amd64
image_amd64:
	$(OCI) build --platform linux/amd64 -t $(IMAGE_AMD64) -f $(IMAGE_FILE) .

.PHONY: image_arm64
image_arm64:
	$(OCI) build --platform linux/arm64/v8 -t $(IMAGE_ARM64) -f $(IMAGE_FILE) .

## dash shell

.PHONY: dash_linux_amd64
dash_linux_amd64: dirs image_amd64 $(DIST)/dash_linux_amd64.tar.xz

.PHONY: dash_linux_arm64
dash_linux_arm64: dirs image_arm64 $(DIST)/dash_linux_arm64.tar.xz

## env

.PHONY: env_linux_amd64
env_linux_amd64: dirs image_amd64 $(DIST)/env_linux_amd64.tar.xz

.PHONY: env_linux_arm64
env_linux_arm64: dirs image_arm64 $(DIST)/env_linux_arm64.tar.xz

## Linux headers

.PHONY: linux_headers_amd64
linux_headers_amd64: dirs image_amd64 $(DIST)/linux_headers_amd64.tar.xz

.PHONY: linux_headers_arm64
linux_headers_arm64: dirs image_arm64 $(DIST)/linux_headers_arm64.tar.xz

## musl

.PHONY: musl_cc_linux_amd64
musl_cc_linux_amd64: dirs $(DIST)/toolchain_amd64_linux_musl.tar.xz

.PHONY: musl_cc_linux_arm64
musl_cc_linux_arm64: dirs $(DIST)/toolchain_arm64_linux_musl.tar.xz

## Macos toolchain

.PHONY: macos_sdk
macos_sdk: dirs $(DIST)/macos_sdk_$(MACOS_SDK_VER).tar.zstd

$(DIST)/macos_sdk_$(MACOS_SDK_VER).tar.zstd: $(WORK)/macos_sdk$(MACOS_SDK_VER).sdk
	tar -C $< --zstd -cf $@ .

CLI_TOOLS_PATH = /Library/Developer/CommandLineTools
$(WORK)/macos_sdk$(MACOS_SDK_VER).sdk:
	mkdir -p $@
	cp -R $(CLI_TOOLS_PATH)/SDKs/MacOSX$(MACOS_SDK_VER).sdk/* $@

.PHONY: macos_toolchain
macos_toolchain: dirs $(DIST)/toolchain_macos.tar.zstd

$(WORK)/toolchain_macos:
	mkdir -p $@ && \
	cp -R $(CLI_TOOLS_PATH)/usr $@ && \
	cp -R $(CLI_TOOLS_PATH)/Library $@ && \
	rm -rf $@/usr/{bin,lib}/swift*

$(DIST)/toolchain_macos.tar.zstd: $(WORK)/toolchain_macos
	tar -C $< --zstd -cf $@ .

## Busybox

.PHONY: busybox_linux_amd64
busybox_linux_amd64: dirs $(DIST)/busybox_amd64_linux.tar.xz

.PHONY: busybox_linux_arm64
busybox_linux_arm64: dirs $(DIST)/busybox_arm64_linux.tar.xz

$(DIST)/busybox_amd64_linux.tar.xz: $(WORK)/x86_64/busybox
	$(SCRIPTS)/build_tangram_tarball.sh $< $@

$(DIST)/busybox_arm64_linux.tar.xz: $(WORK)/aarch64/busybox
	$(SCRIPTS)/build_tangram_tarball.sh $< $@

$(WORK)/aarch64/busybox: $(WORK)/aarch64/busybox-$(BUSYBOX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_busybox.sh $(BUSYBOX_VER)

$(WORK)/x86_64/busybox: $(WORK)/x86_64/busybox-$(BUSYBOX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_busybox.sh $(BUSYBOX_VER)

## dash shell

$(DIST)/dash_linux_amd64.tar.xz: $(WORK)/x86_64/dash
	$(SCRIPTS)/build_tangram_tarball.sh $< $@

$(DIST)/dash_linux_arm64.tar.xz: $(WORK)/aarch64/dash
	$(SCRIPTS)/build_tangram_tarball.sh $< $@

$(WORK)/aarch64/dash: $(WORK)/aarch64/dash-$(DASH_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_dash.sh $(DASH_VER)

$(WORK)/x86_64/dash: $(WORK)/x86_64/dash-$(DASH_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_dash.sh $(DASH_VER)

## env

$(DIST)/env_linux_amd64.tar.xz: $(WORK)/x86_64/env
	$(SCRIPTS)/build_tangram_tarball.sh $< $@

$(DIST)/env_linux_arm64.tar.xz: $(WORK)/aarch64/env
	$(SCRIPTS)/build_tangram_tarball.sh $< $@

$(WORK)/aarch64/env: $(WORK)/aarch64/coreutils-$(COREUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_env.sh $(COREUTILS_VER)

$(WORK)/x86_64/env: $(WORK)/x86_64/coreutils-$(COREUTILS_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_env.sh $(COREUTILS_VER)

## Musl toolchain

$(DIST)/toolchain_%_linux_musl.tar.xz: $(WORK)/toolchain_%_linux_musl.tar.xz
	cp $< $@ 

$(WORK)/toolchain_arm64_linux_musl.tar.xz: $(SOURCES)/aarch64-linux-musl-native.tgz
	$(SCRIPTS)/fix_musl_toolchain_symlink.sh $< $@ aarch64

$(WORK)/toolchain_amd64_linux_musl.tar.xz: $(SOURCES)/x86_64-linux-musl-native.tgz
	$(SCRIPTS)/fix_musl_toolchain_symlink.sh $< $@ x86_64

## Linux API Headers

$(DIST)/linux_headers_amd64.tar.xz: $(WORK)/x86_64/linux_headers
	tar -C $< -cJf $@ .

$(DIST)/linux_headers_arm64.tar.xz: $(WORK)/aarch64/linux_headers
	tar -C $< -cJf $@ .

$(WORK)/x86_64/linux_headers: $(WORK)/x86_64/linux-$(LINUX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) amd64 build_linux_headers.sh $(LINUX_VER)	

$(WORK)/aarch64/linux_headers: $(WORK)/aarch64/linux-$(LINUX_VER)
	$(SCRIPTS)/run_linux_build.sh $(OCI) arm64 build_linux_headers.sh $(LINUX_VER)	

# Sources

$(WORK)/%: $(SOURCES)/%.tar.gz
	cd $(WORK) && \
	tar -xf $<

$(WORK)/aarch64/%: $(SOURCES)/%.tar.gz
	cd $(WORK)/aarch64 && \
	tar -xf $<

$(WORK)/x86_64/%: $(SOURCES)/%.tar.gz
	cd $(WORK)/x86_64 && \
	tar -xf $<

$(WORK)/%: $(SOURCES)/%.tar.bz2
	cd $(WORK) && \
	tar -xf $<

$(WORK)/aarch64/%: $(SOURCES)/%.tar.bz2
	cd $(WORK)/aarch64 && \
	tar -xf $<

$(WORK)/x86_64/%: $(SOURCES)/%.tar.bz2
	cd $(WORK)/x86_64 && \
	tar -xf $<

## Busybox

$(SOURCES)/busybox-$(BUSYBOX_VER).tar.bz2:
	wget -O $@ https://busybox.net/downloads/busybox-$(BUSYBOX_VER).tar.bz2

## dash shell

$(SOURCES)/dash-$(DASH_VER).tar.gz:
	wget -O $@ http://gondor.apana.org.au/~herbert/dash/files/dash-$(DASH_VER).tar.gz

## coreutils

$(SOURCES)/coreutils-$(COREUTILS_VER).tar.gz:
	wget -O $@ https://ftp.gnu.org/gnu/coreutils/coreutils-$(COREUTILS_VER).tar.gz

## Linux

$(WORK)/aarch64/linux-$(LINUX_VER): $(SOURCES)/linux-$(LINUX_VER).tar.xz
	mkdir -p $(WORK)/aarch64 && \
	cd $(WORK)/aarch64 && \
	tar -xf $<

$(WORK)/x86_64/linux-$(LINUX_VER): $(SOURCES)/linux-$(LINUX_VER).tar.xz
	mkdir -p $(WORK)/x86_64 && \
	cd $(WORK)/x86_64 && \
	tar -xf $<

$(SOURCES)/linux-$(LINUX_VER).tar.xz:
	wget -O $@ https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(LINUX_VER).tar.xz

# musl.cc

$(SOURCES)/aarch64-linux-musl-native.tgz:
	wget -O $@ https://musl.cc/aarch64-linux-musl-native.tgz

$(SOURCES)/x86_64-linux-musl-native.tgz:
	wget -O $@ https://musl.cc/x86_64-linux-musl-native.tgz
