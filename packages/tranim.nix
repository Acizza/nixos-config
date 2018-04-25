with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "tranim-${version}";
    version = "3aaae079b9024cd9c83efe6d6e48e2d05b9ff9a1";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "tranim";
        rev = "${version}";
        sha256 = null;
    };
    
    cargoSha256 = null;
    
    nativeBuildInputs = [ openssl pkgconfig ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.all;
    };
}
