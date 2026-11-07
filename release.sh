#!/bin/zsh
# Builds a Developer ID signed, notarized and stapled universal app and zips it for a GitHub release.
# Requires (App Store Connect API key for notarization):
#   SIGN_IDENTITY="Developer ID Application: Name (TEAMID)"
#   NOTARY_KEY_ID=…  NOTARY_ISSUER=…  [NOTARY_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_<id>.p8]
set -euo pipefail

cd "$(dirname "$0")"

: "${SIGN_IDENTITY:?set SIGN_IDENTITY}"
: "${NOTARY_KEY_ID:?set NOTARY_KEY_ID}"
: "${NOTARY_ISSUER:?set NOTARY_ISSUER}"
NOTARY_KEY_PATH="${NOTARY_KEY_PATH:-$HOME/.appstoreconnect/private_keys/AuthKey_${NOTARY_KEY_ID}.p8}"

export SIGN_IDENTITY
./build-app.sh

APP="build/Show Hidden Files.app"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' Resources/Info.plist)"
ZIP="build/ShowHiddenFiles-${VERSION}-universal.zip"

rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"
xcrun notarytool submit "${ZIP}" --wait \
    --key "${NOTARY_KEY_PATH}" --key-id "${NOTARY_KEY_ID}" --issuer "${NOTARY_ISSUER}"
xcrun stapler staple "${APP}"

# Re-zip so the download carries the stapled ticket and opens offline too.
rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"
spctl --assess --type execute --verbose "${APP}"

# DMG with a drag-to-Applications window (layout matches Resources/generate-dmg-background.swift).
VOLUME="Show Hidden Files"
DMG="build/ShowHiddenFiles-${VERSION}-universal.dmg"
STAGE="build/dmg-stage"
RW_DMG="build/dmg-rw.dmg"

rm -rf "${STAGE}" "${RW_DMG}" "${DMG}"
mkdir -p "${STAGE}/.background"
ditto "${APP}" "${STAGE}/Show Hidden Files.app"
ln -s /Applications "${STAGE}/Applications"
cp Resources/dmg-background.png "${STAGE}/.background/background.png"
chflags hidden "${STAGE}/.background"

[[ -d "/Volumes/${VOLUME}" ]] && hdiutil detach "/Volumes/${VOLUME}" -force
hdiutil create -quiet -volname "${VOLUME}" -srcfolder "${STAGE}" -fs HFS+ -format UDRW -ov "${RW_DMG}"
DEVICE="$(hdiutil attach -readwrite -noverify -noautoopen "${RW_DMG}" | awk '/^\/dev\// {print $1; exit}')"

osascript <<EOF
tell application "Finder"
    tell disk "${VOLUME}"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        -- 660×440 background plus ~70 pt for the toolbar newer Finders keep showing; extra space below is white.
        set the bounds of container window to {200, 120, 860, 630}
        set opts to the icon view options of container window
        set arrangement of opts to not arranged
        set icon size of opts to 128
        set text size of opts to 13
        set background picture of opts to file ".background:background.png"
        set position of item "Show Hidden Files.app" of container window to {180, 220}
        set position of item "Applications" of container window to {480, 220}
        set extension hidden of item "Show Hidden Files.app" to true
        -- Users of this app often show hidden files; park dot-items outside the window.
        try
            set position of item ".background" of container window to {900, 900}
        end try
        try
            set position of item ".fseventsd" of container window to {1000, 900}
        end try
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

sync
hdiutil detach "${DEVICE}" -quiet
hdiutil convert "${RW_DMG}" -quiet -format UDZO -imagekey zlib-level=9 -o "${DMG}"
rm -rf "${STAGE}" "${RW_DMG}"

codesign --force --timestamp --sign "${SIGN_IDENTITY}" "${DMG}"
xcrun notarytool submit "${DMG}" --wait \
    --key "${NOTARY_KEY_PATH}" --key-id "${NOTARY_KEY_ID}" --issuer "${NOTARY_ISSUER}"
xcrun stapler staple "${DMG}"
spctl --assess --type open --context context:primary-signature --verbose "${DMG}"

echo "Release archives:"
echo "  $(pwd)/${ZIP}"
echo "  $(pwd)/${DMG}"
