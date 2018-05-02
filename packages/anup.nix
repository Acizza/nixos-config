with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "dc956330b34d105c7518d9b311e62a1079beefe2";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "anup";
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
