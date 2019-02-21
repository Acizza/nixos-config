{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "1ed59638fd09e6738d45cc1b68add17f31c5bacd";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "15r6n69mbhsfmskx45idcs47c7dd8f1qgx540z1sls8ldypzdx4v";
    };
    
    cargoSha256 = "095dl08p5c2plahr9y8jr7kqav3s7w2kfzgpxiw4270lzm0g1nwc";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
