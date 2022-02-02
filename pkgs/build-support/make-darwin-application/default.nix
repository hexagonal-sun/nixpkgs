# given a package with an executable and an icon, make a darwin application for
# it. This package should be used when generating launchers for native Darwin
# applications. If the package conatins a .desktop file use
# `desktop2DarwinLauncher` instead.

{ lib, writeShellScript, writeDarwinLauncher }:

{ name # The name of the Application file.
, exec # Executable file.
, icon ? "" # Optional icon file.
}:

writeShellScript "make-darwin-application-${name}" (''
  function makeDarwinApplicationPhase() {
    mkdir -p "$out/Applications/${name}.app/Contents/MacOS"
    mkdir -p "$out/Applications/${name}.app/Contents/Resources"

    if [ -n "${icon}" ]; then
      ln -s "${icon}" "$out/Applications/${name}.app/Contents/Resources"
    fi

    ${writeDarwinLauncher}/bin/write-darwin-launcher "$out" "${name}" "${exec}" "$(basename "${icon}")"
  }

  preDistPhases+=" makeDarwinApplicationPhase"
'')
