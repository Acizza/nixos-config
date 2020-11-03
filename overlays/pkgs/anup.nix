{ rustPlatform, fetchFromGitHub, stdenv, pkgconfig, sqlite, xdg_utils }:

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "4fcb35127447021ce3462e76e8b68bcb56ea33b5";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "J0hSnG9mQ0m0AUaiErAV6LMezBrDSyQEepeq7T+Pqwg=";
    };
    
    cargoSha256 = "F65RAdPgWLywjw0HQfbCx4esrsDiRvftOOBUaVaeRDw=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with stdenv.lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
