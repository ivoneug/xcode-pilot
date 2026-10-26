export PATH="$PATH:/opt/homebrew/bin"

if which swiftgen >/dev/null; then
    cd Scripts/SwiftGen/
    swiftgen config run --config swiftgen.yml
else
    echo "warning: SwiftGen not installed, download it from https://github.com/SwiftGen/SwiftGen"
    exit 1
fi

