#!/bin/sh
# Teaches the 2018-era build system about Apple Silicon.
#
# binutils 2.30 and gdb 8.1 ship a config.guess/config.sub pair from before
# Apple Silicon existed, so they cannot name an arm64 macOS host at all. Refresh
# every copy in the tree from upstream gnu config.
#
# Nothing else is needed: gdb 8.1's configure.host already routes any *-*-darwin*
# host to gdb_host=darwin, and it has no config/*/*.mh fragments to supply (that
# mechanism was replaced by configure.nat before 8.1). Native darwin support is
# not compiled in regardless, since this is a cross debugger targeting stm8.
set -e

SRCDIR="binutils-${BINUTILS_VERSION:-2.30}"
WORK="$(pwd)"
BASE="https://git.savannah.gnu.org/cgit/config.git/plain"

echo "==> Refreshing config.guess / config.sub"
curl -fsSL --retry 3 -o "${WORK}/config.guess.new" "${BASE}/config.guess"
curl -fsSL --retry 3 -o "${WORK}/config.sub.new" "${BASE}/config.sub"

# Sanity check - an error page would otherwise be copied over dozens of files.
head -1 "${WORK}/config.guess.new" | grep -q '^#!' || {
  echo "downloaded config.guess is not a script" >&2; exit 1; }
head -1 "${WORK}/config.sub.new" | grep -q '^#!' || {
  echo "downloaded config.sub is not a script" >&2; exit 1; }

find "$SRCDIR" -name config.guess -exec cp "${WORK}/config.guess.new" {} \; -exec chmod +x {} \;
find "$SRCDIR" -name config.sub   -exec cp "${WORK}/config.sub.new" {} \;   -exec chmod +x {} \;

echo "==> Host now detected as: $(sh "${SRCDIR}/config.guess")"
