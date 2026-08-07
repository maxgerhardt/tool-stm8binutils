#!/bin/sh
# Renders package.json.in into the install tree.
#
# Takes one or more PlatformIO system identifiers, comma or space separated. A
# single build can legitimately serve several of them: armv7l and armv8l are the
# same 32-bit arm userspace, the latter being what uname reports when a 64-bit
# kernel is in use, so one set of binaries covers both.
set -e

SYSTEMS="$1"
ROOT="${2:-installed}"
VERSION="${PKG_VERSION:-0.230.0}"

if [ -z "$SYSTEMS" ]; then
  echo "usage: $0 <platformio-system>[,<system>...] [install-root]" >&2
  exit 1
fi

# Build the JSON array entries, comma separated but not after the last one.
block=""
first=1
for s in $(printf '%s' "$SYSTEMS" | tr ',' ' '); do
  if [ "$first" = 1 ]; then
    block="    \"${s}\""
    first=0
  else
    block="${block},
    \"${s}\""
  fi
done

awk -v repl="$block" '{ if ($0 == "@SYSTEMS@") print repl; else print }' \
  package.json.in | sed -e "s|@VERSION@|${VERSION}|g" >"${ROOT}/package.json"

cat "${ROOT}/package.json"
