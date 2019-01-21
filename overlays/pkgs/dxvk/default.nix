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
  version = "v0.95";

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
      sha256 = "1j06028dx5n7x5s492yiw6jlhmps70s4viiph57pvi4c0p4yag7k";
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
