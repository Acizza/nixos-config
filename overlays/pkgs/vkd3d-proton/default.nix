{ stdenv,
  lib,
  pkgsCross,
  fetchgit,
  meson,
  ninja,
  glslang,
  wine,
  windows,
}:

stdenv.mkDerivation rec {
  pname = "vkd3d-proton";
  version = "d00d035321c9f817e058985e32fe6876ba746de6";

  src = fetchgit {
    url = "https://github.com/HansKristian-Work/vkd3d-proton.git";
    rev = version;
    sha256 = "sha256-74wY65e7Fkfjhqo435euztTA6g4Mw7h0rBAXGQQRu/4=";
  };

  phases = "unpackPhase patchPhase postPatchPhase buildPhase installPhase";

  buildInputs = with pkgsCross.mingw32.windows; [
    mcfgthreads
    pthreads
  ] ++ (with pkgsCross.mingwW64.windows; [
    mcfgthreads
    pthreads
  ]);

  nativeBuildInputs = with pkgsCross; [
    meson
    ninja
    glslang
    mingw32.buildPackages.gcc
    mingwW64.buildPackages.gcc
    wine
  ];

  hardeningDisable = [ "all" ];
  strictDeps = true;

  patches = [
    # Fixes a compiler error with mingw
    ./explicitly_define_hex_base.patch
    # vkd3d will fail to initialize if this isn't present in the Wine prefix
    ./copy_mcfgthreads_dll.patch
    # Allows the setup_vkd3d script to work in fresh wine prefixes
    ./create_d3d12_dll.patch
  ];

  postPatchPhase = let
    mcfgthreadsDll = variant: "${variant}/bin/mcfgthread-12.dll";
  in ''
    # The patchShebangs hook does not appear to replace this
    substituteInPlace setup_vkd3d_proton.sh --replace \
      "#!/bin/bash" \
      "#!${stdenv.shell}"

    substituteInPlace setup_vkd3d_proton.sh --replace \
      "__MCFGTHREADS_64_DLL__" \
      "${mcfgthreadsDll pkgsCross.mingwW64.windows.mcfgthreads}"

    substituteInPlace setup_vkd3d_proton.sh --replace \
      "__MCFGTHREADS_32_DLL__" \
      "${mcfgthreadsDll pkgsCross.mingw32.windows.mcfgthreads}"
  '';

  buildPhase =
    let
      builder = ./builder.sh;
    in ''
      source ${builder}
      build_vkd3d 64
      build_vkd3d 32
    '';

  installPhase = ''
    mkdir -p $out/bin/
    cp setup_vkd3d_proton.sh $out/bin/setup_vkd3d
    chmod +x $out/bin/setup_vkd3d
  '';
  
  meta = with lib; {
    platforms = platforms.linux;
    license = licenses.lgpl21;
  };
}