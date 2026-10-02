#!/bin/bash
# Copy all DLLs from $MINGW_PREFIX/bin that the given binaries (recursively) depend on.
#
# usage: scripts/collect-dlls.sh DESTDIR BINARY...
set -euo pipefail

dest=$1
shift

objdump=$(command -v objdump || command -v llvm-objdump)
bindir="$MINGW_PREFIX/bin"

declare -A seen
queue=("$@")

while [ ${#queue[@]} -gt 0 ]; do
    bin=${queue[0]}
    queue=("${queue[@]:1}")
    [ -f "$bin" ] || continue

    while read -r dll; do
        key=${dll,,}
        [ -n "${seen[$key]:-}" ] && continue
        seen[$key]=1

        # system DLLs are not in the MSYS2 prefix and are skipped
        src=$(find "$bindir" -maxdepth 1 -iname "$dll" -print -quit)
        [ -n "$src" ] || continue

        echo "  $dll"
        cp "$src" "$dest/"
        queue+=("$src")
    done < <("$objdump" -p "$bin" | sed -n 's/^\s*DLL Name: //p' | tr -d '\r')
done
