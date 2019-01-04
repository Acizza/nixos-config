{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "1ce7e6a11dd19381de263e27ac8d675e3b778588";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "15xdymdbgd4dwl43gsby24dwwnxiv1fm2zm2b7i61jh14lv19a3n";
    };
    
    cargoSha256 = "13f9yrmai2qcl7v0sls4z1aj3357yn5m70qr4pqm7yds71dm39h6";
    
    nativeBuildInputs = with pkgs; [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = with pkgs; [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
