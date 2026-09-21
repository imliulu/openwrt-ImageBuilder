#!/usr/bin/env bash
set -euo pipefail

VERSION="${OPENWRT_VERSION:-25.12.5}"
TARGET="mediatek"
SUBTARGET="filogic"
PLATFORM="${TARGET}-${SUBTARGET}"
PROFILE="glinet_gl-mt3600be"
IMAGE="openwrt/imagebuilder:${PLATFORM}-${VERSION}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$ROOT_DIR/.cache/${PLATFORM}-${VERSION}"

mkdir -p "$ROOT_DIR/bin" "$CACHE_DIR/dl"

cat > "$ROOT_DIR/files/etc/custom-build.conf" <<EOF2
LAN_IP='${LAN_IP:-192.168.8.1}'
HOSTNAME='${HOSTNAME:-mt3600be}'
TIMEZONE='${TIMEZONE:-CST-8}'
ZONENAME='${ZONENAME:-Asia/Shanghai}'
EOF2

cat > "$ROOT_DIR/files/etc/build-info" <<EOF2
FIRMWARE_VERSION='${FIRMWARE_VERSION:-dev}'
OPENWRT_VERSION='$VERSION'
TARGET='$TARGET/$SUBTARGET'
PROFILE='$PROFILE'
BUILD_TIME='$(date -u +%Y-%m-%dT%H:%M:%SZ)'
GIT_COMMIT='$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)'
EOF2

echo "==> Pulling $IMAGE"
docker pull "$IMAGE"

echo "==> Building $PROFILE / OpenWrt $VERSION"
docker run --rm \
  -e PROFILE="$PROFILE" \
  -e EXTRA_IMAGE_NAME="custom" \
  -v "$ROOT_DIR/bin:/builder/bin" \
  -v "$CACHE_DIR/dl:/builder/dl" \
  -v "$ROOT_DIR/files:/custom-files:ro" \
  -v "$ROOT_DIR/config:/custom-config:ro" \
  -v "$ROOT_DIR/scripts/build.sh:/builder/custom-build.sh:ro" \
  "$IMAGE" \
  sh /builder/custom-build.sh

echo "==> Output"
find "$ROOT_DIR/bin" -type f -maxdepth 6 -print | sort
