#!/usr/bin/env bash
fixupOutputHooks+=('convertDesktopFiles $prefix')

# Get a param out of a desktop file. First parameter is the file and the second
# is a pattern of the key who's value we should fetch.
getDesktopParam() {
    local file="$1";
    local pattern="$2";

    awk -F "=" "/${pattern}/ {print \$2}" "${file}"
}

getPngSize() {
  local -r png="$1"

  identify -verbose "$png" | grep Geometry | cut -f 2 -d ':' | cut -f 1 -d '+' | xargs
}

# For a given .desktop file, generate a darwin '.app' launcher for it.
convertDesktopFile() {
    local -r file="$1"
    local -r name=$(getDesktopParam "${file}" "^Name")
    local -r exec=$(getDesktopParam "${file}" "Exec")
    local -r iconName=$(getDesktopParam "${file}" "Icon")
    local -r iconFiles=$(find "$out/share/icons/" -name "${iconName}.png");
    local convertableIcons=""

    mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
    mkdir -p "$out/Applications/${name}.app/Contents/Resources"

    for icon in $iconFiles; do
      local sz=$(getPngSize "$icon");

      if [ $sz = "16x16" ] ||
         [ $sz = "32x32" ] ||
         [ $sz = "48x48" ] ||
         [ $sz = "128x128" ] ||
         [ $sz = "256x256" ] ||
         [ $sz = "512x512" ] ||
         [ $sz = "1024x1024" ]; then
        convertableIcons="$convertableIcons $icon";
      fi
    done

    if [ -n "$convertableIcons" ]; then
        png2icns "$out/Applications/${name}.app/Contents/Resources/icon.icns" $convertableIcons;
    fi

    write-darwin-launcher "$out" "$name" "$exec" "icon.icns"
}

convertDesktopFiles() {
    local dir="$1/share/applications/"

    if [ -d "${dir}" ]; then
        for desktopFile in $(find "$dir" -iname "*.desktop"); do
            convertDesktopFile "$desktopFile";
        done
    fi
}
