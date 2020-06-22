{ rustPlatform, fetchFromGitHub, stdenv, pkgs }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "07b5feda0191ea85a4f657d81399b10c1dbef4ba";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "1qgnw9w9psgn8pywqbp9ajkhn667vvxrsak8ms8pn6zm4m5av3gr";
    };
    
    cargoSha256 = "09pa5356gfn55l46d1qbqsdv09wp3n9xvyzawpvwxna53hi3bkjj";
    
    buildInputs = let
      sqlite = pkgs.sqlite.overrideAttrs (oldAttrs: rec {
        NIX_CFLAGS_COMPILE = oldAttrs.NIX_CFLAGS_COMPILE or "" + " -DSQLITE_USE_URI=1";
      });
    in [ stdenv.cc.cc sqlite.dev ];

    meta = with stdenv.lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
