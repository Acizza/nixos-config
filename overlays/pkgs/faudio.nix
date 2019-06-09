{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.06.07";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "1w37qp279lgpyvslwz3wlb4fp0i68ncd411rqdlk5s71b1zz466n";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    patches = [ ../patches/faudio_take_dir_for_sdl_includes.patch ];

    NIX_CFLAGS_COMPILE = "-I${SDL2.dev}/include/SDL2";
  }