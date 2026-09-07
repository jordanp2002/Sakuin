#!/bin/zsh

set -euo pipefail

project_dir=${0:A:h:h}
binary_path=${1:-"$project_dir/.build/release/Sakuin"}
output_dir="$project_dir/dist"
app_bundle="$output_dir/Sakuin.app"
temporary_bundle="$output_dir/.Sakuin.app.building"

if [[ ! -x "$binary_path" ]]; then
    print -u2 "Missing release executable: $binary_path"
    exit 1
fi

rm -rf "$temporary_bundle"
mkdir -p "$temporary_bundle/Contents/MacOS" "$temporary_bundle/Contents/Resources"
cp "$binary_path" "$temporary_bundle/Contents/MacOS/Sakuin"
cp "$project_dir/Packaging/Info.plist" "$temporary_bundle/Contents/Info.plist"
chmod 755 "$temporary_bundle/Contents/MacOS/Sakuin"

codesign --force --deep --sign - "$temporary_bundle"
plutil -lint "$temporary_bundle/Contents/Info.plist"
codesign --verify --deep --strict "$temporary_bundle"

rm -rf "$app_bundle"
mv "$temporary_bundle" "$app_bundle"
print "$app_bundle"
