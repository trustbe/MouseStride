#!/bin/bash
set -e

APP_NAME="MouseStride"
TARGET_NAME="MouseStride"
APP_BUNDLE="${APP_NAME}.app"
INSTALL_DIR="/Applications"

echo "==> Installing ${APP_NAME}..."

# Check macOS version (requires 13.0+ Ventura)
macos_version=$(sw_vers -productVersion)
major=$(echo "$macos_version" | cut -d. -f1)
if [ "$major" -lt 13 ]; then
    echo "Error: ${APP_NAME} requires macOS 13.0 (Ventura) or later. You have ${macos_version}."
    exit 1
fi

# Build release binary
echo "==> Building release binary..."
swift build -c release

# Create app bundle
echo "==> Creating app bundle..."
BUILD_DIR=".build/release"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"

mkdir -p "$MACOS"
cp "${BUILD_DIR}/${TARGET_NAME}" "${MACOS}/${APP_NAME}"
cp Sources/MouseStride/App/Info.plist "${CONTENTS}/Info.plist"

# Kill any running instance
echo "==> Stopping any running instance..."
pkill -x "$APP_NAME" 2>/dev/null || true

# Install to /Applications
echo "==> Installing to ${INSTALL_DIR}..."
if [ -d "${INSTALL_DIR}/${APP_BUNDLE}" ]; then
    rm -rf "${INSTALL_DIR}/${APP_BUNDLE}"
fi
cp -R "$APP_BUNDLE" "${INSTALL_DIR}/"

# Launch the app
echo "==> Launching ${APP_NAME}..."
open "${INSTALL_DIR}/${APP_BUNDLE}"

echo ""
echo "Done! ${APP_NAME} is now running in your menu bar."
