#!/bin/sh

set -eu

PROFILE="${PROFILE:-cudy_tr3000-256mb-v1}"

PACKAGE_FILE="${PACKAGE_FILE:-/custom-device/packages.txt}"

CUSTOM_FILES="${CUSTOM_FILES:-/custom-files}"

EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME:-custom}"


# --------------------------------------------------
# Check package list
# --------------------------------------------------

if [ ! -f "$PACKAGE_FILE" ]; then

    echo "ERROR: package list not found: $PACKAGE_FILE" >&2

    exit 1

fi


# --------------------------------------------------
# Initialize ImageBuilder
#
# OpenWrt 24.10+ Docker ImageBuilder 使用轻量 wrapper。
#
# 第一次运行时 setup.sh 会下载并解压真正的
# ImageBuilder。
# --------------------------------------------------

if [ ! -d ./scripts ] && [ -x ./setup.sh ]; then

    echo "==> Initializing OpenWrt ImageBuilder"

    ./setup.sh

fi


# --------------------------------------------------
# Verify ImageBuilder
# --------------------------------------------------

if [ ! -f ./Makefile ]; then

    echo "ERROR: ImageBuilder Makefile is missing after setup" >&2

    exit 1

fi


# --------------------------------------------------
# Read package list
#
# 自动忽略：
#
#   空行
#   # 注释
# --------------------------------------------------

PACKAGES="$(awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { printf "%s ", $0 }
' "$PACKAGE_FILE")"


echo "==> PROFILE=$PROFILE"

echo "==> EXTRA_IMAGE_NAME=$EXTRA_IMAGE_NAME"

echo "==> PACKAGES=$PACKAGES"


# --------------------------------------------------
# Verify device profile
#
# 防止 PROFILE 写错以后构建整个过程才失败。
# --------------------------------------------------

if ! make info 2>/dev/null | grep -Fq "$PROFILE"; then

    echo "ERROR: profile '$PROFILE' not found in ImageBuilder" >&2

    echo "Available matching Cudy profiles:" >&2

    make info 2>/dev/null \
        | grep -i -A2 -B1 'cudy' >&2 \
        || true

    exit 1

fi


# --------------------------------------------------
# Build OpenWrt image
# --------------------------------------------------

make image \
    PROFILE="$PROFILE" \
    PACKAGES="$PACKAGES" \
    FILES="$CUSTOM_FILES" \
    EXTRA_IMAGE_NAME="$EXTRA_IMAGE_NAME"


echo "==> Build finished"


# --------------------------------------------------
# Show generated firmware
# --------------------------------------------------

find bin/targets \
    -maxdepth 4 \
    -type f \
    -print \
    | sort