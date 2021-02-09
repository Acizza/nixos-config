{ rustPlatform,
  fetchFromGitHub,
  stdenv,
  lib,
  pkgconfig,
  sqlite,
  xdg_utils
}:

rustPlatform.buildRustPackage rec {
    pname = "anup";
    version = "0.1.1";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "oL7dCXKpZKqfwFPX7NAVJ9AJq4o2tSX9fadQOTC9ogY=";
    };
    
    cargoSha256 = "c36xugGBz8cSvEcGggPk9NvOcR1IzXoOOxwzwG8rLFs=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
