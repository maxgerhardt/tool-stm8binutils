#!/bin/sh
# Fails the build if a shipped binary depends on anything a user is not
# guaranteed to already have.
#
# The whole point of staging static archives is that the only runtime
# dependency left is the system C library. This asserts that stayed true, so a
# dependency creeping back in breaks CI instead of breaking users.
set -e

BIN="$1"
if [ -z "$BIN" ]; then
  echo "usage: $0 <binary>" >&2
  exit 1
fi

echo "==> Runtime dependencies of ${BIN}"
status=0

case "$(uname -s)" in
  Darwin)
    otool -L "$BIN"
    # Only the OS-provided frameworks and libSystem are acceptable. Anything
    # under /opt/homebrew or /usr/local came from the build machine.
    offenders=$(otool -L "$BIN" | tail -n +2 | awk '{print $1}' \
      | grep -v '^/usr/lib/' | grep -v '^/System/Library/' || true)
    ;;
  MINGW*|MSYS*|CYGWIN*)
    # Note: the system objdump, not the freshly built stm8-objdump - that one
    # is a cross tool that only understands stm8 ELF and cannot read PE at all.
    objdump -p "$BIN" | grep -i 'DLL Name' | sort -u
    # Windows' own DLLs are fine; anything MSYS2 supplied is not. Those are
    # named libfoo-N.dll, msys-2.0.dll or zlib1.dll, none of which a user has.
    offenders=$(objdump -p "$BIN" | grep -i 'DLL Name' | awk '{print $3}' \
      | grep -iE '^(msys-|lib|zlib)' || true)
    ;;
  *)
    # readelf rather than ldd: ldd only works on binaries the host can run,
    # and the arm cross builds are inspected from an x86_64 host. readelf reads
    # any ELF regardless of its architecture. The interpreter and vdso are not
    # DT_NEEDED entries, so they drop out of this list on their own.
    "${READELF:-readelf}" -d "$BIN" | grep NEEDED || true
    offenders=$("${READELF:-readelf}" -d "$BIN" \
      | sed -n 's/.*NEEDED.*\[\(.*\)\].*/\1/p' \
      | grep -Ev '^(libm\.so\.6|libc\.so\.6|libdl\.so\.2|libpthread\.so\.0|librt\.so\.1|libgcc_s\.so\.1)$' || true)
    ;;
esac

if [ -n "$offenders" ]; then
  echo ""
  echo "ERROR: ${BIN} depends on libraries users are not guaranteed to have:" >&2
  echo "$offenders" | sed 's/^/  /' >&2
  status=1
else
  echo "OK: only system libraries required"
fi

exit $status
