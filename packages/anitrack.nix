with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anitrack-${version}";
    version = "a499269a16d52a00af0ec23a10c98fa4f4a552c3";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "anitrack";
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
