{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "7cd25ae36fe35328360f08e853a21e4bb84206b0";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "0ika22s2di0mp8zwvpmd1v5vpc5cjis49g4lbi8194kr9pjir3y1";
    };
    
    cargoSha256 = "0j2n8q298ckmybx969h4b7xawq3pwdll3ghiaqn0wcwhmjjf30k8";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
