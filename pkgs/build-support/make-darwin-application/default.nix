# given a package with an executable and an icon, make a darwin application for it.

{ lib, writeShellScript }:

{ name # The name of the Application file
, exec
, icon ? null
, version
}:

let
  plist = {
    "CFBundleDevelopmentRegion" = "English";
    "CFBundleExecutable" = name;
    "CFBundleIconFile" = "${name}.icns";
    "CFBundleIdentifier" = "org.nixos.${name}";
    "CFBundleInfoDictionaryVersion" = "6.0";
    "CFBundleName" = name;
    "CFBundlePackageType" = "APPL";
    "CFBundleShortVersionString" = version;
    "CFBundleSignature" = "???";
    "CFBundleVersion" = version;
  };

  plistStrings = [
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">"
    "<plist version=\"1.0\">"
    "  <dict>"
  ] ++ builtins.filter
      (v: v != null)
      (lib.mapAttrsToList
        (name: value: "    <key>${name}</key><string>${value}</string>")
        plist
      )
    ++ [
      "  </dict>"
      "</plist>"
    ];
in
  writeShellScript "make-darwin-application-${name}" (''
    function makeDarwinApplicationPhase() {
    mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
    mkdir -p "$out/Applications/${name}.app/Contents/Resources"
    cat > "$out/Applications/${name}.app/Contents/Info.plist" <<EOF
    ${builtins.concatStringsSep "\n" plistStrings}
    EOF
    cat > "$out/Applications/${name}.app/Contents/MacOS/${name}" <<EOF
    #!/bin/bash
    exec ${exec}
    EOF
    chmod +x "$out/Applications/${name}.app/Contents/MacOS/${name}"
  '' + lib.optionalString (icon != null) ''
    ln -s ${icon} $out/Applications/${name}.app/Contents/Resources/${name}.icns
  '' + ''
    }

    preDistPhases+=" makeDarwinApplicationPhase"
  '')
