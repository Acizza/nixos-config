{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.04";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "00lqf8bjcwm4k8yky9jmqghkxijcm2lxspb9zyl1270yqmj05kiw";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    NIX_CFLAGS_COMPILE = "-I${SDL2.dev}/include/SDL2";
  }