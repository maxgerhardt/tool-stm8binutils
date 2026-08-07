#!/bin/sh
# Collects the static archives of gdb's third-party dependencies into a single
# directory.
#
# Passing -L<that directory> ahead of the system library paths makes the linker
# resolve -lfoo to libfoo.a rather than to the shared object, because both ld and
# Apple's linker search -L directories in order and take the first hit. The
# result is a binary that carries readline, ncurses, expat and friends inside it
# and asks the user's machine only for its C library.
#
# That is what makes the shipped binaries standalone: a user needs a new enough
# glibc (or macOS), and nothing else installed.
#
# Usage: SEARCH_DIRS="dir1 dir2" ./stage_static_libs.sh <destdir> <lib>...
set -e

DEST="$1"
shift

if [ -z "$DEST" ] || [ $# -eq 0 ]; then
  echo "usage: SEARCH_DIRS=... $0 <destdir> <lib>..." >&2
  exit 1
fi
if [ -z "$SEARCH_DIRS" ]; then
  echo "SEARCH_DIRS is not set" >&2
  exit 1
fi

rm -rf "$DEST"
mkdir -p "$DEST"

for lib in "$@"; do
  found=""
  for dir in $SEARCH_DIRS; do
    if [ -f "${dir}/lib${lib}.a" ]; then
      cp "${dir}/lib${lib}.a" "${DEST}/"
      found="${dir}/lib${lib}.a"
      break
    fi
  done
  if [ -z "$found" ]; then
    echo "ERROR: no static lib${lib}.a in any of: ${SEARCH_DIRS}" >&2
    exit 1
  fi
  echo "  staged ${found}"
done

echo "Static dependency archives in ${DEST}:"
ls -la "$DEST"
