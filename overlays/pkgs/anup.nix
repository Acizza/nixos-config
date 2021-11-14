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
    version = "7964bf3c22cb139a705f7ff90f5c229c553650ba";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "OLbzCEW07l/OF/tWbsDLLASdpSthVCWKGIzyIDVsbOg=";
    };
    
    cargoSha256 = "yWkcyPOeRLuRhD2RMP9yZB7C1wQDThWBSvXrg+zjp7g=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
