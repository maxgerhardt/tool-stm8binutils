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
WORK="$(pwd)"

echo "==> Refreshing config.guess"
curl -fsSL --retry 3 -o "${WORK}/config.guess.new" \
  "https://git.savannah.gnu.org/cgit/config.git/plain/config.guess"

# Sanity check - an error page would otherwise be copied over dozens of files.
head -1 "${WORK}/config.guess.new" | grep -q '^#!' || {
  echo "downloaded config.guess is not a script" >&2; exit 1; }

find "$SRCDIR" -name config.guess -exec cp "${WORK}/config.guess.new" {} \; -exec chmod +x {} \;

echo "==> Host now detected as: $(sh "${SRCDIR}/config.guess")"
echo "==> Target still resolves: $(sh "${SRCDIR}/config.sub" stm8-none-elf32)"
