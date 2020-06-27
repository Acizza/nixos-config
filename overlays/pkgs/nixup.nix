{ rustPlatform, fetchFromGitHub, stdenv, pkgs }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "c2298cf334bdee422c7b7ac3b0c73220ac926a48";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "037l1al1d8mz6jmi9z0syp20q58fb5z2xs5gfqvhgxxaqzzpxrld";
    };
    
    cargoSha256 = "1nx7hkkpg1c6gwppcbi747hvls91s04zcs8vjdwfxw1y943i3bsg";
    
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
