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
    
    cargoSha256 = "1m7vzlmw3awcgrdg1ianhcfwhlqv7xhd97b8jrvj0c726n4zkw3p";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
