{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.05";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "1dja2ykixk1ycqda116cg9fy4qg364dqj88amfln0r9pnsj2kbxk";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    patches = [ ../patches/faudio_take_dir_for_sdl_includes.patch ];

    NIX_CFLAGS_COMPILE = "-I${SDL2.dev}/include/SDL2";
  }