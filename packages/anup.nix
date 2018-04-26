with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "579ff2983d45dfad13c5ae05c69c2db5fff91399";
    
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
