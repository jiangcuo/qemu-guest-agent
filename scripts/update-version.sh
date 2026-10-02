#!/bin/bash
# Update VERSION to a new QEMU release.
#
# usage: scripts/update-version.sh [VERSION]
#
# Without VERSION the latest stable QEMU release is used.
set -euo pipefail

TOPDIR=$(cd "$(dirname "$0")/.." && pwd)
QEMU_GIT=${QEMU_GIT:-https://gitlab.com/qemu-project/qemu.git}

# shellcheck source=VERSION
. "$TOPDIR/VERSION"

version=${1:-}
if [ -z "$version" ]; then
    version=$(git ls-remote --tags --refs "$QEMU_GIT" 'v*' \
        | sed -n 's|.*refs/tags/v\([0-9]\+\.[0-9]\+\.[0-9]\+\)$|\1|p' \
        | sort -V | tail -n1)
    [ -n "$version" ] || { echo "unable to determine latest QEMU version" >&2; exit 1; }
fi

if [ "$version" = "$QEMU_VERSION" ]; then
    echo "already at QEMU $version"
    exit 0
fi

cat > "$TOPDIR/VERSION" <<EOV
# managed by scripts/update-version.sh - sourced by the CI and shell scripts
QEMU_VERSION=$version
PKG_RELEASE=1
EOV

message="update to QEMU $version"
echo "$message"
if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
        echo "changed=true"
        echo "message=$message"
    } >> "$GITHUB_OUTPUT"
fi
