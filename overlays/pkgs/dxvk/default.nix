{ multiStdenv,
  fetchFromGitHub,
  pkgs,
  stdenv,
  winePackage ? pkgs.wineWowPackages.unstable
}:

let
  version = "v0.93";
in
  multiStdenv.mkDerivation {
    name = "dxvk-${version}";

    src = fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "${version}";
      sha256 = "0f8qz2sz82ph1f3i4yzgjcrq0w2xljx23g6frh4gf35rkfmamrh8";
    };

    buildInputs = with pkgs; [ meson ninja glslang ] ++ [ winePackage ];

    phases = "unpackPhase buildPhase fixupPhase";

    buildPhase =
      let
        builder = ./builder.sh;
      in ''
        source ${builder}
        build_dxvk 64
        build_dxvk 32
      '';

    fixupPhase = ''
      substituteInPlace $out/bin/setup_dxvk64 --replace \
        "#!/bin/bash" \
        "#!${stdenv.shell}"

      substituteInPlace $out/bin/setup_dxvk32 --replace \
        "#!/bin/bash" \
        "#!${stdenv.shell}"
    '';
    
    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = [ licenses.zlib licenses.png ];
    };
  }
