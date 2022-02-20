#!/usr/bin/env bash
fixupOutputHooks+=('convertDesktopFiles $prefix')

# Get a param out of a desktop file. First parameter is the file and the second
# is a pattern of the key who's value we should fetch.
getDesktopParam() {
    local file="$1";
    local pattern="$2";

    awk -F "=" "/${pattern}/ {print \$2}" "${file}"
}

# For a given .desktop file, generate a darwin '.app' bundle for it.
convertDesktopFile() {
    local -r file="$1"
    local -r name=$(getDesktopParam "${file}" "^Name")
    local -r exec=$(getDesktopParam "${file}" "Exec")
    local -r iconName=$(getDesktopParam "${file}" "Icon")
    local -ar iconFiles=($(find "$out/share/icons/" -name "${iconName}.*" 2>/dev/null))
    local -ar pixMaps=($(find "$out/share/pixmaps/" -name "${iconName}.xpm" 2>/dev/null))

    mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
    mkdir -p "$out/Applications/${name}.app/Contents/Resources"

    local -a convertedPixMaps
    for pixmap in $pixMaps; do
        local newIconName=$(mktemp --suffix=.png);
        convertedPixMaps+=($newIconName)
        convert "$pixmap" "$newIconName"
    done

    echo pnging to icons
    png2icns "$out/Applications/${name}.app/Contents/Resources/${name}.icns" "${iconFiles[@]}" "${convertedPixMaps[@]}"

    write-darwin-bundle "$out" "$name" "$exec"
}

convertDesktopFiles() {
    local dir="$1/share/applications/"

    if [ -d "${dir}" ]; then
        for desktopFile in $(find "$dir" -iname "*.desktop"); do
            convertDesktopFile "$desktopFile";
        done
    fi
}
