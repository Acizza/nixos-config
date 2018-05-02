with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "c0cf3f83500914365c9c4a2737027c3b5d6a2792";
    
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
