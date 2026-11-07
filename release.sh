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

echo "Release archive: $(pwd)/${ZIP}"
