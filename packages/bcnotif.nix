with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "c70ae69c16029dff80fd2c1c0d697707cac41a79";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = null;
    };
    
    cargoSha256 = null;
    
    nativeBuildInputs = [ openssl dbus pkgconfig ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.all;
    };
}
