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
  version = "v1.5.2";

  src = fetchFromGitHub {
    owner = "doitsujin";
    repo = "dxvk";
    rev = version;
    sha256 = "10pv9j0g0ffz4cvxghn104hy1qjyx51ndrg0n2giwhk1688lkfm9";
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
