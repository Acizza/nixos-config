{ rustPlatform, fetchFromGitLab, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "58cecb3c9c7d9045e39fbab49f02f417299f7f26";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "0bf7k2drca0db73kzy9glxwzwl5sfkggbjs9zphzbvgpdxaccvig";
    };
    
    cargoSha256 = "0dnhcgrp641gjrfsmahmswrpwjiq2ilpn6i3zgjw7p4v501p1hms";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
