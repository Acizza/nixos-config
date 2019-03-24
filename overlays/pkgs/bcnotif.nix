{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "b83a72b7d520485d23a3d3dc0f83b8f02cbd91a4";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "1v2qqx9wrfdn6zqgndwj1m86b9ab5iq970vmf7d21xkbkk9kf7bx";
    };
    
    cargoSha256 = "1v3002skk0nfbs3z3a38ic8wprgy5dz47x344zwd8gp10iv6gkys";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
