#!/bin/bash
# Regenerate src/<variant>/ from a pinned Ubuntu kernel source archive:
# verified pristine source files + the local patch.
#
# Usage: scripts/regen.sh 7.0 [dest_dir]
# The default archive is installed by `apt install linux-source-7.0.0` at
# /usr/src/linux-source-7.0.0.tar.bz2. Override it with KERNEL_SOURCE_ARCHIVE,
# or provide an already extracted tree with KERNEL_SOURCE_TREE.
set -euo pipefail

V=${1:?usage: regen.sh 7.0 [dest_dir]}
[ "$V" = 7.0 ] || { echo "unsupported source variant: $V (only 7.0 is included)" >&2; exit 1; }

ROOT=$(cd "$(dirname "$0")/.." && pwd)
MAN="$ROOT/provenance/$V.manifest"
[ -f "$MAN" ] || { echo "no manifest: $MAN" >&2; exit 1; }

patch_file=$(awk '$1=="patch"{print $2}' "$MAN")
source_root=$(awk '$1=="source-root"{print $2}' "$MAN")
archive_default=$(awk '$1=="source-archive"{print $2}' "$MAN")
[ -n "$patch_file" ] && [ -n "$source_root" ] && [ -n "$archive_default" ] || {
    echo "incomplete source metadata in $MAN" >&2
    exit 1
}

DEST=${2:-$ROOT/src/$V}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mapfile -t paths < <(awk '$1=="file"{print $3}' "$MAN")
[ "${#paths[@]}" -gt 0 ] || { echo "no source files listed in $MAN" >&2; exit 1; }

if [ -n "${KERNEL_SOURCE_TREE:-}" ]; then
    source_dir=$(cd "$KERNEL_SOURCE_TREE" && pwd)
else
    archive=${KERNEL_SOURCE_ARCHIVE:-$archive_default}
    [ -r "$archive" ] || {
        echo "Ubuntu 7.0 kernel source archive not found: $archive" >&2
        echo "Install it with: sudo apt install linux-source-7.0.0" >&2
        exit 1
    }
    archive_paths=()
    for path in "${paths[@]}"; do archive_paths+=("$source_root/$path"); done
    archive_paths+=("$source_root/Makefile")
    tar -xjf "$archive" -C "$work" -- "${archive_paths[@]}"
    source_dir="$work/$source_root"
fi

if [ ! -f "$source_dir/Makefile" ]; then
    echo "not a Linux source tree: $source_dir" >&2
    exit 1
fi
version=$(awk '$1=="VERSION"{v=$3} $1=="PATCHLEVEL"{p=$3} END{print v "." p}' "$source_dir/Makefile")
[ "$version" = 7.0 ] || {
    echo "expected Linux 7.0 source, got $version from $source_dir/Makefile" >&2
    exit 1
}

mkdir -p "$DEST"
while read -r _ sha path dest apply; do
    [ -n "${sha:-}" ] || continue
    src="$source_dir/$path"
    [ -f "$src" ] || { echo "source file missing: $path" >&2; exit 1; }
    got=$(sha256sum "$src" | cut -d' ' -f1)
    [ "$got" = "$sha" ] || {
        echo "sha256 mismatch for $path" >&2
        echo "  want $sha" >&2; echo "  got  $got" >&2; exit 1;
    }
    cp "$src" "$work/$dest"
    if [ "$apply" = yes ]; then
        patch -s "$work/$dest" < "$ROOT/$patch_file"
    fi
    cp "$work/$dest" "$DEST/$dest"
    patch_note=""
    [ "$apply" = yes ] && patch_note=" (patch applied)"
    echo "  ok  $dest$patch_note"
done < <(awk '$1=="file"{print}' "$MAN")

echo "regenerated $DEST from $MAN"
