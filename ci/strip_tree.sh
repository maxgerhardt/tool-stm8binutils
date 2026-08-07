#!/bin/sh
# Strips every real executable and shared library in the install tree.
#
# The tree also holds linker scripts, gdb's python helpers, man pages and info
# files, so we ask file(1) what each one is rather than stripping by glob.
set -e

ROOT=${1:-installed}

# STRIP is overridable so the arm cross builds can use their own
# arm-linux-gnueabihf-strip; the host strip cannot touch a foreign-arch ELF.
STRIP_CMD=${STRIP:-strip}

case "$(uname -s)" in
  Darwin)
    # Plain `strip` mangles Mach-O executables; -S -x drops debug info and
    # local symbols while leaving the binary loadable.
    STRIP_ARGS="-S -x"
    RESIGN=1
    ;;
  *)
    STRIP_ARGS="--strip-all"
    RESIGN=0
    ;;
esac

echo "Install tree before stripping: $(du -sh "$ROOT" | cut -f1)"

find "$ROOT" -type f -print | while IFS= read -r f; do
  case "$(file -b "$f" 2>/dev/null)" in
    *ELF*executable*|*ELF*shared\ object*|*PE32*executable*|*PE32*DLL*|*Mach-O*)
      $STRIP_CMD $STRIP_ARGS "$f" 2>/dev/null || continue
      if [ "$RESIGN" = 1 ]; then
        # Stripping invalidates the ad-hoc signature every arm64 Mach-O carries,
        # and an invalidated signature means the kernel SIGKILLs the process on
        # launch. Re-sign ad-hoc to make the binaries runnable again.
        codesign --force --sign - "$f" >/dev/null 2>&1 || true
      fi
      echo "  stripped $f"
      ;;
  esac
done

echo "Install tree after stripping:  $(du -sh "$ROOT" | cut -f1)"
