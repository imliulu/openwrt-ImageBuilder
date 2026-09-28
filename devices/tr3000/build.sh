#!/bin/sh

set -eu


# --------------------------------------------------
# Cudy TR3000 V1 256MB Profile
# --------------------------------------------------

PROFILE="${PROFILE:-cudy_tr3000-256mb-v1}"


# --------------------------------------------------
# Device package list
# --------------------------------------------------

PACKAGE_FILE="${PACKAGE_FILE:-/custom-device/packages.txt}"


# --------------------------------------------------
# Custom root filesystem files
# --------------------------------------------------

CUSTOM_FILES="${CUSTOM_FILES:-/custom-files}"


# --------------------------------------------------
# Custom image name suffix
# --------------------------------------------------

EXTRA_IMAGE_NAME="${EXTRA_IMAGE_NAME:-custom}"


# --------------------------------------------------
# Verify package list
# --------------------------------------------------

if [ ! -f "$PACKAGE_FILE" ]; then

    echo "ERROR: package list not found: $PACKAGE_FILE" >&2

    exit 1

fi


# --------------------------------------------------
# Initialize OpenWrt ImageBuilder
#
# OpenWrt 24.10+ Docker ImageBuilder 可能只包含
# setup.sh wrapper。
#
# 第一次运行时需要执行 setup.sh 下载真正的
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
# Load package list
#
# 自动忽略：
#
# 空行
# # 开头的注释
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
# 如果 25.12.5 ImageBuilder 中不存在这个 Profile，
# 直接退出，避免继续错误构建。
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
# Build firmware
# --------------------------------------------------

make image \
    PROFILE="$PROFILE" \
    PACKAGES="$PACKAGES" \
    FILES="$CUSTOM_FILES" \
    EXTRA_IMAGE_NAME="$EXTRA_IMAGE_NAME"


echo "==> Build finished"


# --------------------------------------------------
# Show generated files
# --------------------------------------------------

find bin/targets \
    -maxdepth 4 \
    -type f \
    -print \
    | sort