{ multiStdenv,
  fetchFromGitHub,
  stdenv,
  meson,
  ninja,
  glslang,
  wine,
}:

multiStdenv.mkDerivation rec {
  pname = "dxvk";
  version = "v1.6-3104192";

  src = fetchFromGitHub {
    owner = "doitsujin";
    repo = "dxvk";
    rev = "3104192af717f309068d2c20fd51b339511f6552";
    sha256 = "1pc8j82zn636dr2ivz8hq628iqwzczjjjazps7p3h7lll1wj2g4c";
  };

  buildInputs = [ meson ninja glslang wine ];

  phases = "unpackPhase patchPhase buildPhase installPhase fixupPhase";

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
