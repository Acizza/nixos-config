{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.08";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "1v13kfhyr46241vb6a4dcb4gw5f149525sprwa9cj4rv6wlcqgm5";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    cmakeFlags = [
      "-DSDL2_INCLUDE_DIRS=${SDL2.dev}/include/SDL2"
      "-DSDL2_LIBRARIES=${SDL2.dev}/lib/"
    ];
  }