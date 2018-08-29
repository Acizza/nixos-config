with import <nixpkgs> {};

let
  version = "0.70";

  setup_dxvk = writeScript "setup_dxvk" ''
    #!${stdenv.shell}
    winetricks --force @out@/share/dxvk/setup_dxvk.verb
  '';
in
  stdenv.mkDerivation {
    name = "dxvk-${version}";
    
    src = fetchurl {
        url = "https://github.com/doitsujin/dxvk/releases/download/v${version}/dxvk-${version}.tar.gz";
        sha256 = "17sfvz8rx2bjvxdw5ahiv1lk41sbxxzp16z4r8slljdy63alc19i";
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
    '';
    
    meta = with stdenv.lib; {
        platforms = platforms.linux;
    };
  }
