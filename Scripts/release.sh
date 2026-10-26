#!/bin/bash
# Builds build/release/XcodePilot.dmg: archived in Release, signed with the team's Developer ID, notarized
# and stapled, ready to attach to a GitHub release.
#
# Needs the "Developer ID Application" certificate of DEVELOPMENT_TEAM_ID (Scripts/project.env) in the
# keychain and a notarytool keychain profile, xcode-pilot-notary by default (NOTARY_PROFILE overrides it):
#   xcrun notarytool store-credentials xcode-pilot-notary --apple-id <Apple ID> --team-id <team>
set -euo pipefail

cd "$(dirname "$0")"
set -a
. ./project.env
set +a

PROFILE=${NOTARY_PROFILE:-xcode-pilot-notary}
ROOT=$(cd .. && pwd)
OUT=$ROOT/build/release
ARCHIVE=$OUT/$PROJECT_NAME.xcarchive
APP=$OUT/export/$TARGET_NAME.app
DMG=$OUT/$PROJECT_NAME.dmg
# Outside the repository: SwiftLint runs from its root and would lint the generated sources
DERIVED_DATA=$HOME/Library/Developer/Xcode/DerivedData/$PROJECT_NAME-release

IDENTITY=$(security find-identity -v -p codesigning | grep "Developer ID Application" | grep "($DEVELOPMENT_TEAM_ID)" | head -1 | awk '{print $2}')
if [ -z "$IDENTITY" ]; then
    echo "No Developer ID Application certificate for team $DEVELOPMENT_TEAM_ID in the keychain" >&2
    exit 1
fi

echo "Generate the project"
./generateProject.sh > /dev/null

# Empties the folder instead of removing it: Finder may be showing it and writing .DS_Store there
mkdir -p "$OUT"
find "$OUT" -mindepth 1 -delete

echo "Archive"
xcodebuild -project "$ROOT/$PROJECT_NAME.xcodeproj" -scheme "$TARGET_NAME" -configuration Release \
    -destination 'generic/platform=macOS' -derivedDataPath "$DERIVED_DATA" \
    -archivePath "$ARCHIVE" archive -quiet

echo "Export with Developer ID"
cat > "$OUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>teamID</key>
    <string>$DEVELOPMENT_TEAM_ID</string>
</dict>
</plist>
EOF
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist "$OUT/ExportOptions.plist" \
    -exportPath "$OUT/export" -allowProvisioningUpdates -quiet

VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$APP/Contents/Info.plist")
echo "Version $VERSION"

# The app is notarized on its own too, so a copy dragged out of the DMG opens without a network check
echo "Notarize the app"
ditto -c -k --keepParent "$APP" "$OUT/$TARGET_NAME.zip"
xcrun notarytool submit "$OUT/$TARGET_NAME.zip" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
rm "$OUT/$TARGET_NAME.zip"

echo "Make the DMG"
mkdir "$OUT/dmg"
ditto "$APP" "$OUT/dmg/$TARGET_NAME.app"
ln -s /Applications "$OUT/dmg/Applications"
hdiutil create -volname "$APP_DISPLAY_NAME" -srcfolder "$OUT/dmg" -fs HFS+ -format UDZO -ov "$DMG" > /dev/null
codesign --sign "$IDENTITY" --timestamp "$DMG"

echo "Notarize the DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"

echo "Check with Gatekeeper"
spctl --assess --type execute --verbose "$APP"
spctl --assess --type open --context context:primary-signature --verbose "$DMG"

echo "Done: $DMG ($VERSION)"
