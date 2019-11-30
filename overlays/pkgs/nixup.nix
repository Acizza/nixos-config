{ rustPlatform, fetchFromGitHub, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "35fa0fb245725f6337a7066c71287d6e9c91701c";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "087ci7bq2n7y99g5cj3xmkfig9fkriclb87brjw1splxssallb2w";
    };
    
    cargoSha256 = "1xxdk8zwdxp1lnj8j79m1gy4j0pc6nmx7gv3kn99ym0n07rjw3vv";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
