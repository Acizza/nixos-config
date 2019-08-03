{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.07";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "1wf6skc5agaikc9qgwk8bx56sad31fafs53lqqn4jmx8i76pl0lw";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    patches = [ ../patches/faudio_take_dir_for_sdl_includes.patch ];

    NIX_CFLAGS_COMPILE = "-I${SDL2.dev}/include/SDL2";
  }