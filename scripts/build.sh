#!/bin/sh
set -eu

PROFILE="${PROFILE:-glinet_gl-mt3600be}"
PACKAGE_FILE="${PACKAGE_FILE:-/custom-config/packages.txt}"
CUSTOM_FILES="${CUSTOM_FILES:-/custom-files}"
EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME:-custom}"

if [ ! -f "$PACKAGE_FILE" ]; then
    echo "ERROR: package list not found: $PACKAGE_FILE" >&2
    exit 1
fi

# OpenWrt Docker ImageBuilder images (24.10+) may be lightweight wrappers.
# setup.sh downloads/unpacks the real ImageBuilder on first use.
if [ ! -d ./scripts ] && [ -x ./setup.sh ]; then
    echo "==> Initializing OpenWrt ImageBuilder"
    ./setup.sh
fi

if [ ! -f ./Makefile ]; then
    echo "ERROR: ImageBuilder Makefile is missing after setup" >&2
    exit 1
fi

PACKAGES="$(awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { printf "%s ", $0 }
' "$PACKAGE_FILE")"

echo "==> PROFILE=$PROFILE"
echo "==> EXTRA_IMAGE_NAME=$EXTRA_IMAGE_NAME"
echo "==> PACKAGES=$PACKAGES"

# Fail fast if the requested profile is not present in this ImageBuilder.
if ! make info 2>/dev/null | grep -Fq "$PROFILE"; then
    echo "ERROR: profile '$PROFILE' not found in ImageBuilder" >&2
    echo "Available matching GL.iNet profiles:" >&2
    make info 2>/dev/null | grep -i -A2 -B1 'glinet' >&2 || true
    exit 1
fi

make image \
    PROFILE="$PROFILE" \
    PACKAGES="$PACKAGES" \
    FILES="$CUSTOM_FILES" \
    EXTRA_IMAGE_NAME="$EXTRA_IMAGE_NAME"

echo "==> Build finished"
find bin/targets -maxdepth 4 -type f -print | sort
