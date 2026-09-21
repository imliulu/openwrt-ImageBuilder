#!/bin/sh

set -eu

: "${PROFILE:?PROFILE is required}"
: "${PACKAGE_FILE:?PACKAGE_FILE is required}"

EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME:-r5s-custom}"
CUSTOM_FILES="/custom-files"

# Docker ImageBuilder 首次启动时准备实际构建环境
if [ ! -d ./scripts ]; then
    ./setup.sh
fi

# 读取额外软件包。
# packages.txt 可以为空，只使用官方 profile 默认软件包。
PACKAGES=""

if [ -f "$PACKAGE_FILE" ]; then
    PACKAGES="$(
        awk '
            /^[[:space:]]*#/ { next }
            /^[[:space:]]*$/ { next }
            { printf "%s ", $0 }
        ' "$PACKAGE_FILE"
    )"
fi

echo "========================================"
echo "OpenWrt NanoPi R5S Build"
echo "========================================"
echo "PROFILE:           ${PROFILE}"
echo "PACKAGE_FILE:      ${PACKAGE_FILE}"
echo "PACKAGES:          ${PACKAGES:-<none>}"
echo "FILESYSTEM:        squashfs"
echo "EXTRA_IMAGE_NAME:  ${EXTRA_IMAGE_NAME}"
echo "CUSTOM_FILES:      ${CUSTOM_FILES}"
echo "========================================"

make image \
    PROFILE="${PROFILE}" \
    PACKAGES="${PACKAGES}" \
    FILES="${CUSTOM_FILES}" \
    EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME}" \
    ROOTFS_FILESYSTEM="squashfs"

echo
echo "========================================"
echo "R5S build completed"
echo "========================================"

find bin/targets \
    -maxdepth 3 \
    -type f \
    -name '*friendlyarm_nanopi-r5s*' \
    -print 2>/dev/null || true