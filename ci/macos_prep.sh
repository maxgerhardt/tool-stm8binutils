#!/bin/sh
# Teaches the 2018-era build system about Apple Silicon.
#
# Two separate problems:
#
#  1. binutils 2.30 / gdb 8.1 ship a config.guess and config.sub from before
#     Apple Silicon existed, so they cannot name the host at all. We refresh
#     every copy in the tree from upstream gnu config.
#
#  2. gdb 8.1's configure.host has no aarch64 darwin entry, so configure aborts
#     with "*** Configuration aarch64-apple-darwin is not supported". We only
#     ever build a *cross* debugger here (host arm64 macOS, target stm8), so no
#     native darwin debugging support is needed - an empty host fragment is
#     enough to get past the check.
set -e

SRCDIR="binutils-${BINUTILS_VERSION:-2.30}"
WORK="$(pwd)"

echo "==> Refreshing config.guess / config.sub"
curl -fsSL --retry 3 -o "${WORK}/config.guess.new" \
  'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
curl -fsSL --retry 3 -o "${WORK}/config.sub.new" \
  'https://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'

# Sanity check - a gitweb error page would otherwise be copied over 40 files.
head -1 "${WORK}/config.guess.new" | grep -q '^#!' || {
  echo "downloaded config.guess is not a script" >&2; exit 1; }
head -1 "${WORK}/config.sub.new" | grep -q '^#!' || {
  echo "downloaded config.sub is not a script" >&2; exit 1; }

find "$SRCDIR" -name config.guess -exec cp "${WORK}/config.guess.new" {} \; -exec chmod +x {} \;
find "$SRCDIR" -name config.sub   -exec cp "${WORK}/config.sub.new" {} \;   -exec chmod +x {} \;

echo "==> Adding aarch64 darwin host entry to gdb"
if ! grep -q 'aarch64\*-\*-darwin' "${SRCDIR}/gdb/configure.host"; then
  # Insert ahead of the existing aarch64 linux rule so the more specific darwin
  # pattern is reached first.
  perl -0pi -e 's{^(aarch64\*-\*-linux\*)}{aarch64*-*-darwin*\t\tgdb_host=darwin ;;\n\n$1}m' \
    "${SRCDIR}/gdb/configure.host"
fi
grep -n 'aarch64' "${SRCDIR}/gdb/configure.host"

mkdir -p "${SRCDIR}/gdb/config/aarch64"
cat >"${SRCDIR}/gdb/config/aarch64/darwin.mh" <<'EOF'
# Host fragment for arm64 macOS.
# Intentionally empty: this tree only ever builds a cross debugger, so no
# native darwin target support is compiled in.
EOF

echo "macOS preparation done"
