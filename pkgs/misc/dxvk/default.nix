{ lib
, pkgs
, stdenv
, fetchFromGitHub
, pkgsCross
# Make it easy for users to build different versions of DXVK if those have better compatability
# with their games.
, srcVersion ? "1.9.4" # Can also be a Git commit hash
, srcHash ? "sha256-JGSyTYb8iGjb3zJrCIM1nuMPmnUAnlPORVKU29x6eTU="
, dxvkPatches ? [ ]
}:

let
  src = fetchFromGitHub {
    owner = "doitsujin";
    repo = "dxvk";
    rev = version;
    hash = srcHash;
  };
  # Patch DXVK to work with MoltenVK even though it doesn’t support some required features.
  # Some games will work poorly (particularly Unreal Engine 4 games), but others work pretty well.
  patches = lib.optional stdenv.isDarwin [ ./darwin-dxvk-compat.patch ] ++ dxvkPatches;
  # Assume anything over 40 characters is a SHA-1 or SHA-256 commit hash.
  version = "${lib.optionalString (builtins.stringLength srcVersion >= 40) "v"}${srcVersion}";
  dxvk32 = pkgsCross.mingw32.callPackage ./dxvk.nix { inherit src version patches; };
  dxvk64 = pkgsCross.mingwW64.callPackage ./dxvk.nix { inherit src version patches; };
in
stdenv.mkDerivation {
  name = "dxvk";
  inherit src version;

  outputs = [ "out" "bin" "lib" ];

  # Also copy `mcfgthread-12.dll` due to DXVK’s being built in a MinGW cross environment.
  patches = [ ./mcfgthread.patch ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin $bin $lib
    substitute setup_dxvk.sh $out/bin/setup_dxvk.sh \
      --subst-var-by mcfgthreads32 "${pkgsCross.mingw32.windows.mcfgthreads}" \
      --subst-var-by mcfgthreads64 "${pkgsCross.mingwW64.windows.mcfgthreads}" \
      --replace 'basedir=$(dirname "$(readlink -f $0)")' "basedir=$bin"
    chmod a+x $out/bin/setup_dxvk.sh
    declare -A dxvks=( [x32]=${dxvk32} [x64]=${dxvk64} )
    for arch in "''${!dxvks[@]}"; do
      ln -s "''${dxvks[$arch]}/bin" $bin/$arch
      ln -s "''${dxvks[$arch]}/lib" $lib/$arch
    done
  '';

  # DXVK with MoltenVK requires a patched MoltenVK in addition to its own patches. Provide a
  # convenience function to create a Wine compatible with this setup.
  # Usage:
  # let
  #   patchedMoltenVK = dxvk.patchMoltenVK darwin.moltenvk;
  # in
  # wine64Packages.full.override { moltenvk = patchedMoltenVK; vkd3dSupport = false; }
  passthru.patchMoltenVK = moltenvk:
    moltenvk.overrideAttrs (old: {
      patches = old.patches or [ ] ++ [
        # Lie to DXVK about certain features that DXVK expects to be available and set defaults
        # for better performance/compatability on certain hardware.
        ./darwin-moltenvk-compat.patch
      ];
    });

  meta = {
    description = "A Vulkan-based translation layer for Direct3D 9/10/11";
    homepage = "https://github.com/doitsujin/dxvk";
    changelog = "https://github.com/doitsujin/dxvk/releases";
    maintainer = [ lib.maintainers.reckenrode ];
    license = lib.licenses.zlib;
    platforms = lib.platforms.unix;
  };
}
