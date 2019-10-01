{stdenv, fetchFromGitHub, cmake, SDL2, ffmpeg}:

let
  version = "19.10";
in
  stdenv.mkDerivation {
    name = "faudio-${version}";

    src = fetchFromGitHub {
      owner = "FNA-XNA";
      repo = "FAudio";
      rev = "${version}";
      sha256 = "1z7j803nxhgvjwpxr1m5d490yji727v7pn0ghhipbrfxlwzkw1sz";
    };

    buildInputs = [ cmake SDL2.dev ffmpeg ];

    cmakeFlags = [
      "-DFFMPEG=ON"
    ];
  }