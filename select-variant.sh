#!/bin/sh
# DKMS PRE_BUILD hook: select the source matching this checkout's target kernel.
# This repository intentionally carries only the Ubuntu Linux 7.0 source.
#
# Usage: select-variant.sh [kernelver]
# Runs from the build/source root (DKMS runs PRE_BUILD there).

set -e

kv="${1:-$(uname -r)}"
base="${kv%%-*}"             # e.g. 7.0.0-34-generic -> 7.0.0

case "$base" in
    7.0.*) variant=7.0 ;;
    *)
        echo "csr8510-fix: this checkout supports kernel 7.0.x; got '$kv'" >&2
        exit 1
        ;;
esac

srcdir="$(dirname "$0")/src/$variant"
[ -d "$srcdir" ] || {
    echo "csr8510-fix: missing source directory $srcdir" >&2
    exit 1
}

echo "csr8510-fix: kernel $kv -> source variant src/$variant"
cp -f "$srcdir"/*.c "$srcdir"/*.h "$(dirname "$0")/"
