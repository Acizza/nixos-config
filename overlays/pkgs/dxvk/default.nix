{ multiStdenv,
  fetchFromGitHub,
  stdenv,
  meson,
  ninja,
  glslang,
  wine,
}:

let
  version = "v1.3.4";
in
  multiStdenv.mkDerivation {
    name = "dxvk-${version}";

    src = fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "${version}";
      sha256 = "0r7vcig0scnh22lll5a0zivlq1pmg24jrxb0ga1digvj3r31nn8f";
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
