with import <nixpkgs> {};

let
  version = "0.81";

  setup_dxvk = writeScript "setup_dxvk" ''
    #!${stdenv.shell}
    winetricks --force @out@/share/dxvk/setup_dxvk.verb
  '';
in
  stdenv.mkDerivation {
    name = "dxvk-${version}";
    
    src = fetchurl {
        url = "https://github.com/doitsujin/dxvk/releases/download/v${version}/dxvk-${version}.tar.gz";
        sha256 = "0s9qlkv5fajlvnn9sl9b36x4pyix036fkpq7kr84prsfmslyvxlv";
    };
    
    phases = "unpackPhase installPhase fixupPhase";
    
    installPhase = ''
      mkdir -p $out/share/dxvk/
        
      cp -r x32 $out/share/dxvk/
      cp -r x64 $out/share/dxvk/
      cp setup_dxvk.verb $out/share/dxvk/setup_dxvk.verb

      mkdir -p $out/bin/
    '';

    fixupPhase = ''
      substitute ${setup_dxvk} $out/bin/setup_dxvk --subst-var out
      chmod +x $out/bin/setup_dxvk

      # This allows new versions to overwrite the previous one
      # https://github.com/doitsujin/dxvk/issues/569#issuecomment-414537585
      substituteInPlace $out/share/dxvk/setup_dxvk.verb --replace \
        "cp " \
        "cp --remove-destination "
    '';
    
    meta = with stdenv.lib; {
        platforms = platforms.linux;
    };
  }
