{ writeScriptBin, lib, ... }:

let
  pListText = lib.generators.toPlist { } {
    CFBundleDevelopmentRegion = "English";
    CFBundleExecutable = "$name";
    CFBundleIconFile = "$icon";
    CFBundleIdentifier = "org.nixos.$name";
    CFBundleInfoDictionaryVersion = "6.0";
    CFBundleName = "$name";
    CFBundlePackageType = "APPL";
    CFBundleSignature = "???";
  };

in writeScriptBin "write-darwin-launcher" ''
    readonly prefix="$1"
    readonly name="$2"
    readonly exec="$3"
    readonly icon="$4"

    cat > "$prefix/Applications/$name.app/Contents/Info.plist" <<EOF
${pListText}
EOF

    cat > "$prefix/Applications/$name.app/Contents/MacOS/$name" <<EOF
#!/bin/bash
exec $prefix/bin/$exec
EOF

    chmod +x "$prefix/Applications/$name.app/Contents/MacOS/$name"
''
