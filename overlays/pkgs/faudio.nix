{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.03";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "0v5l67ixr5kd9jz5sza8xgzxamqnlgn3gs1q8gg6ir60g0jvzbd4";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    NIX_CFLAGS_COMPILE = "-I${SDL2.dev}/include/SDL2";
  }