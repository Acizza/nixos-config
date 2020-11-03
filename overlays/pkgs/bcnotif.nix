{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "071f3f5cc1d4de7d7b4ad202316cd4bc098665f6";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "DPYi1zbqcS2/gD2wuhF673m6sRDWhtp4IDQ5dvJFZwE=";
    };
    
    cargoSha256 = "TjBBLaEdj5D5JtX6+qrgN5TAe7Q/7Ejmm333Xzqdd7s=";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
