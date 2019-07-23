{ rustPlatform, fetchFromGitLab, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "cf83a14e3999659aad6ce46594cfc0408defc5d0";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "10l2qgcvh8s8n2hsm9wdh58mnb7bqbd1jb34nax6cpyi5xy0z6aa";
    };
    
    cargoSha256 = "138hdk00qashkwqx1gpkg4pfdgcyd3w4w4l4d0ldb24m0h8i87ka";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
