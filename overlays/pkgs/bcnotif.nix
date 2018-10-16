{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "6ce63f9d2cb258443b4ad1c8ab1caf3e45f901ea";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0fw4f420hgbxh2a92y09f8df9dsb3xvznnyp1313sldbhxdbaq85";
    };
    
    cargoSha256 = "1rkxn6rajcf7nnlgsm30dznzgmb69xb07n10lh3w5jlnizpinw0j";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
