#!/bin/sh
# Teaches the 2018-era build system about Apple Silicon.
#
# binutils 2.30 ships a config.guess from before Apple Silicon existed, so it
# cannot name an arm64 macOS host. Refresh every copy from upstream gnu config.
#
# config.sub is deliberately NOT refreshed. Patch 0001 adds stm8 to it, and
# upstream config.sub has never heard of stm8 - replacing it makes configure die
# with "config.sub stm8-none-elf32 failed". The 2.30 config.sub already
# canonicalizes aarch64-apple-darwin correctly, so there is nothing to gain.
#
# Nothing else is needed: gdb 8.1's configure.host already routes any *-*-darwin*
# host to gdb_host=darwin, and it has no config/*/*.mh fragments to supply (that
# mechanism was replaced by configure.nat before 8.1). Native darwin support is
# not compiled in regardless, since this is a cross debugger targeting stm8.
set -e

SRCDIR="binutils-${BINUTILS_VERSION:-2.30}"
NEW_GUESS="$(cd "$(dirname "$0")" && pwd)/config.guess"

# config.guess is vendored rather than downloaded. The savannah endpoint
# intermittently 404s under CI load, and a build that only sometimes finds its
# own toolchain is worse than one pinned to a known-good copy.
[ -f "$NEW_GUESS" ] || { echo "missing vendored ${NEW_GUESS}" >&2; exit 1; }

echo "==> Installing vendored config.guess"
find "$SRCDIR" -name config.guess -exec cp "$NEW_GUESS" {} \; -exec chmod +x {} \;

echo "==> Host now detected as: $(sh "${SRCDIR}/config.guess")"
echo "==> Target still resolves: $(sh "${SRCDIR}/config.sub" stm8-none-elf32)"

# gdb compiles with -I../intl, and macOS filesystems are case-insensitive, so
# libc++'s `#include <version>` resolves to intl/VERSION - a text file reading
# "GNU gettext library from gettext-0.12.1". The compiler then tries to parse
# that as C++ ("unknown type name 'GNU'"), and because <new> includes <version>
# the whole C++ standard library falls over behind it.
#
# The file is purely informational; intl/Makefile.in never references it.
if [ -f "${SRCDIR}/intl/VERSION" ]; then
  echo "==> Removing intl/VERSION (shadows libc++ <version> on case-insensitive filesystems)"
  rm -f "${SRCDIR}/intl/VERSION"
fi
