# Source instead of `export $(xargs < project.env)`: the latter word-splits on the unquoted
# command substitution, so any value containing a space is silently truncated at the space.
set -a
. ./project.env
set +a

echo "Prepare Generated directory"
if [ ! -d ../$PROJECT_NAME/Resources/Generated ]; then
    mkdir ../$PROJECT_NAME/Resources/Generated
fi

echo "Run swiftgen"
(cd SwiftGen && swiftgen config run --config swiftgen.yml)

echo "Run xcodegen"
./xcodegen.sh

echo "Copy IDETemplateMacros.plist"
if [ ! -d ../$PROJECT_NAME.xcodeproj/xcshareddata ]; then
    mkdir ../$PROJECT_NAME.xcodeproj/xcshareddata
fi
cp templates/IDETemplateMacros.plist ../$PROJECT_NAME.xcodeproj/xcshareddata/IDETemplateMacros.plist
