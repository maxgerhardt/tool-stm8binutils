#!/bin/sh
# Renders package.json.in into the install tree for one PlatformIO system.
set -e

SYSTEM="$1"
ROOT="${2:-installed}"
VERSION="${PKG_VERSION:-0.230.0}"

if [ -z "$SYSTEM" ]; then
  echo "usage: $0 <platformio-system> [install-root]" >&2
  exit 1
fi

sed -e "s|@SYSTEM@|${SYSTEM}|g" -e "s|@VERSION@|${VERSION}|g" \
  package.json.in >"${ROOT}/package.json"

cat "${ROOT}/package.json"
