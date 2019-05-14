{ multiStdenv,
  fetchFromGitHub,
  pkgs,
  stdenv,
  meson,
  ninja,
  glslang,
  winePackage ? pkgs.wineWowPackages.unstable,
}:

let
  version = "v1.2";
in
  multiStdenv.mkDerivation {
    name = "dxvk-${version}";

    src = fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "${version}";
      sha256 = "00whrpwnynz87v6nyfvb5sfh6002nh2q81xkqm54r4912irc5qg1";
    };

    buildInputs = [ meson ninja glslang ] ++ [ winePackage ];

    phases = "unpackPhase buildPhase installPhase fixupPhase";

    buildPhase =
      let
        builder = ./builder.sh;
      in ''
        source ${builder}
        build_dxvk 64
        build_dxvk 32
      '';

    installPhase = ''
      cp setup_dxvk.sh $out/share/dxvk/setup_dxvk
      chmod +x $out/share/dxvk/setup_dxvk

      mkdir -p $out/bin/
      ln -s $out/share/dxvk/setup_dxvk $out/bin/setup_dxvk
    '';

    fixupPhase = ''
      substituteInPlace $out/share/dxvk/setup_dxvk --replace \
        "#!/bin/bash" \
        "#!${stdenv.shell}"
    '';
    
    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = [ licenses.zlib licenses.png ];
    };
  }
