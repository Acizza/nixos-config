{ rustPlatform, fetchFromGitHub, stdenv, pkgconfig, sqlite, xdg_utils }:

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "0a05243097f96cc8fb9246e36ea99439120acd09";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "18sav9nvc446d4w4k2mwi9vn17ai0na9ivxz1ysv01ay7bxv0q36";
    };
    
    cargoSha256 = "1vcx4h2s6gyhyjsm18x8iqdpcimlv25j397z19rya758gc1rnzah";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with stdenv.lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
