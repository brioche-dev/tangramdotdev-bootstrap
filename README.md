# Tangram Bootstrap

This repository generates the tarballs required to bootstrap [Tangram](https://www.tangram.dev).

## Usage

The makefile produces a set of Tangram artifacts containing the following utilities:

- `busybox` - sourced from [busybox.net](https://busybox.net/).
- `dash` - sourced from [gondor.apana.org.au](http://gondor.apana.org.au/~herbert/dash/).
- `env` - sourced from [the GNU coreutils](https://www.gnu.org/software/coreutils/).
- `musl-gcc` - sourced from [musl.cc](https://musl.cc).
- Linux API headers - sourced from [kernel.org](https://www.kernel.org).
- `bootstrap_tools_macos` - lacking `busybox`, we instead bundle a minimal build of [toybox](http://landley.net/toybox/) alongside GNU gawk, GNU grep, and `expr` and `tr` from GNU coreutils.

Additionally, we package the macOS build tooling, separated into two artifacts:

- macOS toolchain
- macOS SDK

Run `make` to produce every available tarball in the `dist/` folder.

### Targets

Individual tarballs can be produced using these targets:

- `busybox_linux_amd64`
- `busybox_linux_arm64`
- `dash_linux_amd64`
- `dash_linux_arm64`
- `dash_macos`
- `env_linux_amd64`
- `env_linux_arm64`
- `linux_headers_amd64`
- `linux_headers_arm64`
- `macos_sdk`
- `toolchain_macos`
- `musl_cc_linux_amd64`
- `musl_cc_linux_arm64`
- `bootstrap_tools_macos` - consisting of universal builds of `toybox`, `gawk`, `grep`, `expr`, and `tr`.
- `gawk_macos`
- `grep_macos`
- `toybox_macos`
- `expr_tr_macos`

Additionally, the following housekeeping targets are defined:

- `all` - equivalent to running `make` with no target defined.
- `clean` - clear the `dist/` and `work/` directories.
- `clean_all` - clear everything.
- `clean_dist` - just clear the `dist/` directory.
- `clean_sources` - clear the `sources/` directory.
- `dirs` - produce the `dist/`, `work/` and `sources/` directories, if not already present.
- `image_amd64` - build the `amd64-linux` Docker image.
- `image_arm64` - build the `arm64-linux` Docker image.
- `images` - build both Docker images.
- `list` - enumerate all available targets.

Run `make clean` to remove everything except downloaded sources. Use `make clean_sources` to clear these downloads as well, or `make clean_all` to clean everything at once.

### Prerequisites

This makefile is designed to run on macOS 13.1 or higher.

You also need a container runtime such as [Colima](https://github.com/abiosoft/colima) or [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed.

If your container runtime uses a command other than `docker`, you will need to adjust the value of the `OCI` variable at the top of the Makefile to, e.g. `podman`.
