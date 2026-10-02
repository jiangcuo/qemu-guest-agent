#!/bin/bash
# Build qemu-ga for the current MSYS2 environment and stage it for packaging.
#
# usage (inside an MSYS2 UCRT64 or CLANGARM64 shell): scripts/build.sh
set -euo pipefail

TOPDIR=$(cd "$(dirname "$0")/.." && pwd)
BUILDDIR=${BUILDDIR:-$TOPDIR/build}
STAGEDIR=${STAGEDIR:-$TOPDIR/stage}
QEMU_GIT=${QEMU_GIT:-https://gitlab.com/qemu-project/qemu.git}

# shellcheck source=VERSION
. "$TOPDIR/VERSION"

: "${MINGW_PREFIX:?run this script in an MSYS2 MinGW shell}"

src="$BUILDDIR/qemu-$QEMU_VERSION"
if [ ! -d "$src" ]; then
    mkdir -p "$BUILDDIR"
    git clone --depth 1 --branch "v$QEMU_VERSION" "$QEMU_GIT" "$src"
fi

# LLVM has no windmc; its output does not depend on the architecture, so use the one from
# binutils of another MSYS2 environment, but do not put its other tools into PATH
if ! command -v windmc >/dev/null; then
    for prefix in /ucrt64 /mingw64; do
        [ -x "$prefix/bin/windmc.exe" ] || continue
        mkdir -p "$BUILDDIR/tools"
        cp "$prefix/bin/windmc.exe" "$BUILDDIR/tools/"
        MINGW_PREFIX=$prefix "$TOPDIR/scripts/collect-dlls.sh" "$BUILDDIR/tools" \
            "$BUILDDIR/tools/windmc.exe"
        export PATH="$BUILDDIR/tools:$PATH"
        break
    done
fi

cd "$src"
mkdir -p build
cd build
if [ ! -f build.ninja ]; then
    ../configure \
        --without-default-features \
        --disable-system \
        --disable-user \
        --disable-tools \
        --disable-docs \
        --disable-werror \
        --enable-guest-agent \
        --enable-qga-vss \
        --disable-guest-agent-msi
fi
ninja qemu-ga

rm -rf "$STAGEDIR"
mkdir -p "$STAGEDIR/lib"
cp qga/qemu-ga.exe "$STAGEDIR/"
if [ -f qga/vss-win32/qga-vss.dll ]; then
    cp qga/vss-win32/qga-vss.dll qga/vss-win32/qga-vss.tlb "$STAGEDIR/lib/"
fi

# glib needs the spawn helpers for guest-exec
for helper in "$MINGW_PREFIX"/bin/gspawn-win*-helper*.exe; do
    [ -f "$helper" ] && cp "$helper" "$STAGEDIR/lib/"
done

# collect all DLLs from the MSYS2 prefix the binaries depend on
"$TOPDIR/scripts/collect-dlls.sh" "$STAGEDIR/lib" "$STAGEDIR/qemu-ga.exe" "$STAGEDIR"/lib/*.exe \
    "$STAGEDIR"/lib/*.dll

ls -l "$STAGEDIR" "$STAGEDIR/lib"
"$STAGEDIR/qemu-ga.exe" --version || true
