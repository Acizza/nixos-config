{ rustPlatform, lib, fetchFromGitHub, stdenv, pkgs }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "e312d5c88962c4af6b344711ed167174b214d272";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "J9CayWiRYSCl69u0PUru4gXh5I9gTm+4n958e3XtWOI=";
    };
    
    cargoSha256 = "DJDNE7NFOBiq4JD2l4SZlKSlXW+vOTz8pTBH0tZdht0=";
    
    buildInputs = let
      sqlite = pkgs.sqlite.overrideAttrs (oldAttrs: rec {
        NIX_CFLAGS_COMPILE = oldAttrs.NIX_CFLAGS_COMPILE or "" + " -DSQLITE_USE_URI=1";
      });
    in [ stdenv.cc.cc sqlite.dev ];

    meta = with lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
