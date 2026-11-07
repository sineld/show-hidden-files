#!/bin/zsh
set -euo pipefail

cd "$(dirname "$0")"

echo "Building ShowHiddenFiles (Release, universal)..."
BUILD_ARGS=(-c release --arch arm64 --arch x86_64)
swift build "${BUILD_ARGS[@]}"
BIN_DIR="$(swift build "${BUILD_ARGS[@]}" --show-bin-path)"

APP_NAME="Show Hidden Files.app"
BUILD_DIR="build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}"

rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BIN_DIR}/ShowHiddenFiles" "${APP_BUNDLE}/Contents/MacOS/ShowHiddenFiles"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"
if [[ -f "Resources/AppIcon.icns" ]]; then
    cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

# SIGN_IDENTITY="Developer ID Application: …" signs for distribution; default is a local ad-hoc signature.
if [[ -n "${SIGN_IDENTITY:-}" ]]; then
    codesign --force --options runtime --timestamp --sign "${SIGN_IDENTITY}" "${APP_BUNDLE}"
else
    codesign --force --sign - "${APP_BUNDLE}"
fi

echo "Built app bundle at: $(pwd)/${APP_BUNDLE}"
