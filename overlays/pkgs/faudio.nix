{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.06";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "1azjf972hik1cizsblbvfp38xz7dx368pbpw3pd6z1xk9mnrhi6s";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    patches = [ ../patches/faudio_take_dir_for_sdl_includes.patch ];

    NIX_CFLAGS_COMPILE = "-I${SDL2.dev}/include/SDL2";
  }