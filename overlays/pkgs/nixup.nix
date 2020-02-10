{ rustPlatform, fetchFromGitHub, stdenv, pkgs }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "055897d233cb0c443215e3e7849799134e4e6bef";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "0a6kcsrwq9pphn4j5j4nva1s3rdhzks861b77m47ki093s1lq1a6";
    };
    
    cargoSha256 = "0lbz6n3pzjkr0ymlk7nhybbcd2rdr6fq77mnbx6qsiy5cjbxmwlb";
    
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
