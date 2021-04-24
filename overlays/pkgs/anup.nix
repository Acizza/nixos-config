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
    version = "8dc8213fee8ddec1b719b43069e24deeb9f655e1";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "vpqTILH6TurlXIXnG6L07XqXf2NAExVkq8XT4JBsrp4=";
    };
    
    cargoSha256 = "NSaRFVQDzWLYYdoo52H4prOD/prWBFZMgNhp7XM1r54=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
