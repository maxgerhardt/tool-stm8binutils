#!/bin/sh
# Downloads binutils + gdb and applies the stm8 patch series.
#
# This mirrors patch_binutils.sh but uses curl instead of wget, since wget is
# not present on the macOS runners.
set -e

BINUTILS_VERSION=${BINUTILS_VERSION:-2.30}
GDB_VERSION=${GDB_VERSION:-8.1}

BINUTILS_TARBALL="binutils-${BINUTILS_VERSION}.tar.xz"
GDB_TARBALL="gdb-${GDB_VERSION}.tar.xz"
SRCDIR="binutils-${BINUTILS_VERSION}"

[ -f "$BINUTILS_TARBALL" ] || \
  curl -fSL --retry 3 -o "$BINUTILS_TARBALL" "https://ftp.gnu.org/gnu/binutils/${BINUTILS_TARBALL}"
[ -f "$GDB_TARBALL" ] || \
  curl -fSL --retry 3 -o "$GDB_TARBALL" "https://ftp.gnu.org/gnu/gdb/${GDB_TARBALL}"

rm -rf "$SRCDIR"
mkdir -p "$SRCDIR"

# gdb goes down first, then binutils is unpacked on top of it - the stm8 patches
# expect that combined tree.
tar -xf "$GDB_TARBALL" --strip-components=1 --directory="$SRCDIR"
tar -xf "$BINUTILS_TARBALL"

for f in ./binutils_patches/*.patch; do
  echo "Applying $f"
  patch -N -p 1 -d "$SRCDIR" <"$f"
done

echo "Sources ready in $SRCDIR"
