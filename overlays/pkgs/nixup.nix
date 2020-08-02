{ rustPlatform, fetchFromGitHub, stdenv, pkgs }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "677ab9283175dea1b5084b2c9c34282b1fc394a6";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "0qn8wcdifd0zjdm73sndghhjkprh083wvry0w0mmqymykc4j5iqm";
    };
    
    cargoSha256 = "0zwj57ai43ivr9wrrkmgr9jrwvs8bpjjb14ip4lwd3mqg73rk3k3";
    
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
