{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "3c3dd5a467e89d2dbf3f452c2bb56cfa71fcbaa4";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0gg6fmrxp9k6rhhr5mv1ai36sv3pffbdm7cwiklm5cjm41ci0pmj";
    };
    
    cargoSha256 = "1s128rvsn3x7jx7wmhdj7aqacpkypwryp0d9cajry780gf3b5i7h";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
