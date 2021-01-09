{ rustPlatform, fetchFromGitHub, stdenv, pkgconfig, sqlite, xdg_utils }:

rustPlatform.buildRustPackage rec {
    pname = "anup";
    version = "63cbd60c5d764f1183956ce56a4c9919b2d3e77c";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "/MknZIWLilEoMdXGJMv0h9D+K5ZzPgyxqFQUGxA3bYc=";
    };
    
    cargoSha256 = "FvpJJSRl0ZxYrwF4YFWAKior+j+Vtbg3PxV0ihie1DQ=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with stdenv.lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
