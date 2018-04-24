with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "3bf6c58849b969959627d68b610cb2b725157c1a";
    
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
