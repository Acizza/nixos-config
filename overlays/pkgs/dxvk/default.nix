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
  version = "v1.5.1";

  src = fetchFromGitHub {
    owner = "doitsujin";
    repo = "dxvk";
    rev = version;
    sha256 = "0qsp8lrc911x3fffr4krp87pc9brbaan4wlx7ip3nqaxjanfwam5";
  };

  buildInputs = [ meson ninja glslang wine ];

  phases = "unpackPhase patchPhase buildPhase installPhase fixupPhase";

  patches = [ ./fix_setup_script_hang.patch ];

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
