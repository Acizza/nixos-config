{ multiStdenv,
  fetchFromGitHub,
  pkgs,
  stdenv,
  writeScript,
  meson,
  ninja,
  glslang,
  winePackage ? pkgs.wineWowPackages.unstable,
}:

let
  version = "v0.96";

  setup_dxvk = writeScript "setup_dxvk" ''
    #!${stdenv.shell}
    winetricks --force @out@/share/dxvk/setup_dxvk.verb
  '';
in
  multiStdenv.mkDerivation {
    name = "dxvk-${version}";

    src = fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "${version}";
      sha256 = "0g28nhqvh4v3bs2820kspj9gsljm1g9b45n3kfgz3bdqw1sfnwij";
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
      mkdir -p $out/bin/
      cp utils/setup_dxvk.verb $out/share/dxvk/setup_dxvk.verb
    '';

    fixupPhase = ''
      substituteInPlace $out/share/dxvk/setup_dxvk.verb --replace \
        "cp " \
        "cp --remove-destination "

      substitute ${setup_dxvk} $out/bin/setup_dxvk --subst-var out
      chmod +x $out/bin/setup_dxvk
    '';
    
    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = [ licenses.zlib licenses.png ];
    };
  }
