{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "2f722a202e1fc00b9f659a4370ece8a5628a9a29";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "0f6623aag1m0s39pik0djgmsx53v03nrd99nbl3cn68ipv0jsg9g";
    };
    
    cargoSha256 = "0j2n8q298ckmybx969h4b7xawq3pwdll3ghiaqn0wcwhmjjf30k8";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
