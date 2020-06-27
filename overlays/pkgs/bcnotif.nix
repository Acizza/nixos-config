{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "d70c1fdf18c1e392cecf9a5f439a5af1e7ce2e4d";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0iapndy9kd890xgxdcrcn2yc1bynfppnyscaqwm516qygwysqjm2";
    };
    
    cargoSha256 = "1vb6glh5b8j5mmdm80s8b9kdga92pgmpr0hhr0qygwi5xi7zs3wk";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
