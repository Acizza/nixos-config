{ multiStdenv,
  fetchFromGitHub,
  pkgs,
  stdenv,
  meson,
  ninja,
  glslang,
  wine,
}:

let
  version = "v1.2.3";
in
  multiStdenv.mkDerivation {
    name = "dxvk-${version}";

    src = fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "${version}";
      sha256 = "1v09j260z067zyyq29i666b6jsr8n7r1sz22539mnqvh0dlqzq5y";
    };

    buildInputs = [ meson ninja glslang wine ];

    phases = "unpackPhase patchPhase buildPhase installPhase fixupPhase";

    patches = [ ../../patches/dxvk_fix_setup_script_hang.patch ];

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
