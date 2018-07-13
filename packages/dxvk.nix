with import <nixpkgs> {};

let
  version = "0.54";
in
  stdenv.mkDerivation {
    name = "dxvk-${version}";
    
    src = fetchurl {
        url = "https://github.com/doitsujin/dxvk/releases/download/v${version}/dxvk-${version}.tar.gz";
        sha256 = "0h4nizhd9pssn749ghaznv69xlmx458g1xijp3kjs7d0m9mihbqw";
    };
    
    phases = "unpackPhase preInstallPhase installPhase";
    
    preInstallPhase = ''
        substituteInPlace x32/setup_dxvk.sh --replace /bin/bash ${bash}/bin/bash
        substituteInPlace x64/setup_dxvk.sh --replace /bin/bash ${bash}/bin/bash
    '';
    
    installPhase = ''
        mkdir -p $out/share/dxvk/
        
        cp -r x32 $out/share/dxvk/
        cp -r x64 $out/share/dxvk/
        
        mkdir -p $out/bin/
        
        ln -s $out/share/dxvk/x32/setup_dxvk.sh $out/bin/setup_dxvk32
        ln -s $out/share/dxvk/x64/setup_dxvk.sh $out/bin/setup_dxvk64
    '';
    
    meta = with stdenv.lib; {
        platforms = platforms.linux;
    };
  }
