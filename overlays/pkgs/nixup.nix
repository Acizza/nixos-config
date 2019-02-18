{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "38c78a04069347f1c4946eb6fa1ca8b45ca704a2";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "153v0djaf179id20351rgk3w10gwdphrmd3fz8al6y74jadsarvn";
    };
    
    cargoSha256 = "02lbg21yaifgj42na1j1iamm3c0rbbckaid0yw5qncg4g6afhaxq";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
