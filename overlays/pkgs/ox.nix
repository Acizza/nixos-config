{ rustPlatform, fetchFromGitHub, stdenv, pkgconfig, sqlite, xdg_utils }:

rustPlatform.buildRustPackage rec {
    pname = "ox";
    version = "0.2.6";
    
    src = fetchFromGitHub {
      owner = "curlpipe";
      repo = pname;
      rev = version;
      sha256 = "E3MJEc5H2/pG6R4iZU+ofmOg034x2XXGRbPDcVAP9pI=";
    };
    
    cargoSha256 = "gW4/MBI99edWMqCpdZJFrTBCMqhJ7yV4rhEsBGTj7eI=";
    
    buildInputs = [ stdenv.cc pkgconfig ];
    
    meta = with stdenv.lib; {
      license = licenses.gpl2;
      platforms = platforms.linux;
    };
}
