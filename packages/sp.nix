with import <nixpkgs> {};

stdenv.mkDerivation {
    name = "sp";
    
    src = fetchurl {
        url = https://gist.githubusercontent.com/wandernauta/6800547/raw/2c2ad0f3849b1b1cd1116b80718d986f1c1e7966/sp;
        executable = true;
        sha256 = null;
    };
    
    phases = "installPhase";
    
    installPhase = ''
        mkdir -p $out/bin
        cp $src $out/bin/$name
    '';
    
    meta = with stdenv.lib; {
        description = "A command line tool to interface with Spotify.";
        platforms = platforms.all;
    };
}
