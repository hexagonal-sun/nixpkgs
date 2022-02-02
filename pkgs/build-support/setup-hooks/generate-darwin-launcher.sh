#!/usr/bin/env bash

fixupOutputHooks+=('generateDarwinLaunchers $prefix')

# Get a param out of a desktop file. First parameter is the file and the second
# is a pattern of the key who's value we should fetch.
getDesktopParam() {
    local file="$1";
    local pattern="$2";

    awk -F "=" "/${pattern}/ {print \$2}" "${file}"
}

# Various icons of different sizes are generated for desktop entries. Here we
# use the filesize to select the largest icon (which will presumably have the
# largest resolutioœn) for the launcher.
getIconFile() {
    local -r name="$1"
    local -r candidateIcons=$(find "$out/share/icons/" -name "${name}.png")
    local biggestSz=0
    local currentCandidate=""

    for icon in ${candidateIcons}; do
        local sz=$(stat -c "%s" "${icon}")

        if (( $sz > $biggestSz )); then
            biggestSz=$sz;
            currentCandidate="$icon"
        fi
    done

    echo "$currentCandidate";
}

# For a given .desktop file, generate a darwin '.app' launcher for it.
generateDarwinLauncher() {
    set -x
    local -r file="$1"
    local -r name=$(getDesktopParam "${file}" "^Name")
    local -r exec=$(getDesktopParam "${file}" "Exec")
    local -r iconName=$(getDesktopParam "${file}" "Icon")
    local -r iconFile=$(getIconFile "$iconName")

    mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
    mkdir -p "$out/Applications/${name}.app/Contents/Resources"

    if [ -n "$iconFile" ]; then
        png2icns "$out/Applications/${name}.app/Contents/Resources/icon.icns" "$iconFile";
    fi

    cat > "$out/Applications/${name}.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>CFBundleExecutable</key>
  <string>${name}</string>
  <key>CFBundleIconFile</key>
  <string>icon.icns</string>
  <key>CFBundleIdentifier</key>
  <string>org.nixos.${name}</string>
  <key>CFBundleName</key>
  <string>${name}</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
</dict>
</plist>
EOF

    cat > "$out/Applications/${name}.app/Contents/MacOS/${name}" <<EOF
#!/bin/bash
exec $out/bin/${exec}
EOF

    chmod +x "$out/Applications/${name}.app/Contents/MacOS/${name}"
}

generateDarwinLaunchers() {
    local dir="$1/share/applications/"

    if [ -d "${dir}" ]; then
        for desktopFile in $(find "$dir" -iname "*.desktop"); do
            generateDarwinLauncher "$desktopFile";
        done
    fi
}
