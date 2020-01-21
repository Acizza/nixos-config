{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "5b7bdecb8d9cd95df9b0654281255a116ef67e1c";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "1k5a6n1r2b0rirr7yhzknldw6qmh6j13f5rkq4bdcggbhflznclk";
    };
    
    cargoSha256 = "1zj6llaxl6d4gib4h27ps850rg04j36sprgbs6mi7kdk90148x46";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
