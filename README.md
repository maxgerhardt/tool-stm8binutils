# tool-stm8binutils

STM8 binutils + GDB, packaged for PlatformIO. Built from
[stm8-binutils-gdb](https://stm8-binutils-gdb.sourceforge.io/): binutils 2.30
and gdb 8.1 with the STM8 patch series in `binutils_patches/` applied.

## Branches

`main` holds only sources and CI. The binaries live on one branch per platform,
each rewritten from scratch by every build:

| Branch | PlatformIO `system` | Built on |
|---|---|---|
| `linux_x64` | `linux_x86_64` | ubuntu-22.04, native |
| `linux_aarch64` | `linux_aarch64` | ubuntu-22.04-arm, native |
| `linux_armv7l` | `linux_armv7l`, `linux_armv8l` | debian:11 container, cross-compiled armhf |
| `linux_armv8l` | `linux_armv7l`, `linux_armv8l` | same tree as `linux_armv7l` |
| `linux_armv6l` | `linux_armv6l` | Raspberry Pi OS bullseye, emulated |
| `windows_x64` | `windows_amd64` | MSYS2 MINGW64, statically linked |
| `mac_arm64` | `darwin_arm64` | macos-14, native |
| `mac_x64` | `darwin_x86_64` | macos-15-intel, native |

Only `linux_armv6l` needs emulation. ARMv6 has no native runner, and
Debian/Ubuntu armhf is ARMv7-baseline so those binaries would not run on a Pi 1
or Zero at all — Raspberry Pi OS 32-bit is the only practical source of genuine
ARMv6 libraries. That job takes hours; every other job takes minutes.

`linux_armv7l` cross-compiles from a bullseye container rather than the runner,
so it inherits an old glibc; its binaries are then executed under
`qemu-arm-static` in CI, so the smoke test is real and not just a successful
link.

Each branch root is the install tree directly — `bin/`, `include/`, `share/`,
`stm8-none-elf32/` and `package.json` — so PlatformIO can consume a branch as a
tool package:

```ini
platform_packages =
    tool-stm8binutils@https://github.com/maxgerhardt/tool-stm8binutils.git#linux_x64
```

## Build configuration

All three platforms configure with:

```
--target=stm8-none-elf32 --program-prefix=stm8-
--disable-readline --with-system-readline
--without-python --disable-werror
```

`--disable-readline --with-system-readline` works around a build failure in the
bundled readline copy. `--without-python` keeps `libpython` off the binaries;
linking it dynamically is what produced the `Could not find platform independent
libraries` failures users hit with earlier builds.

## Standalone binaries

The binaries are meant to run on a stock machine with nothing installed
alongside them. `ci/stage_static_libs.sh` collects the static archives of
readline, ncurses, expat, lzma and zlib into one directory that is placed first
in the library search path, so `-lreadline` and friends resolve to `.a` archives
and are linked into the executable. The C library is deliberately left dynamic.

What remains, and all a user needs:

| Package | Runtime requirement |
|---|---|
| `linux_x86_64` | glibc 2.34+ — Ubuntu 22.04+, Debian 12+, RHEL 9+ |
| `linux_aarch64` | glibc 2.34+ |
| `linux_armv7l` | glibc 2.29+ — Raspberry Pi OS buster and later |
| `linux_armv8l` | as `linux_armv7l`; same binaries |
| `linux_armv6l` | glibc 2.31+ — Raspberry Pi OS bullseye and later |
| `windows_amd64` | nothing; fully static, no MSYS2 DLLs |
| `darwin_arm64` | macOS 11.0+; only `/usr/lib` and system frameworks |
| `darwin_x86_64` | macOS 10.13+; only `/usr/lib` and system frameworks |

The macOS builds also pass `--without-mpfr --without-lzma --disable-nls`. Intel
homebrew installs into `/usr/local`, which clang searches by default, so
configure would otherwise absorb whichever optional libraries the runner image
happens to ship and link them as dylibs no user has. Pinning the feature set
keeps both Mac architectures producing identical binaries regardless of what a
future runner image preinstalls.

`ci/check_standalone.sh` enforces this in CI. It inspects the linked binary and
fails the build if any dependency outside that allowlist appears, so a
regression breaks the build rather than reaching users.

Every produced executable is stripped. On macOS stripping invalidates the ad-hoc
code signature that arm64 Mach-O binaries carry, so `ci/strip_tree.sh` re-signs
each one afterwards — without that step the binaries are SIGKILLed on launch.

## Running a build

Push to `main`, or trigger it by hand:

```sh
gh workflow run build.yml
```

Each job also uploads its install tree as a workflow artifact, so a build can be
inspected even if the branch push fails.

## Building locally

```sh
./ci/fetch_sources.sh
cd binutils-2.30
./configure --prefix="$PWD/../installed" --target=stm8-none-elf32 \
    --program-prefix=stm8- --disable-readline --with-system-readline \
    --without-python --disable-werror
make -j"$(nproc)" && make install
```

See `README.txt` for the original upstream instructions.
