{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "wpfxm-${version}";
    version = "v0.1.0";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "wpfxm";
        rev = "${version}";
        sha256 = "17zzj6z6m13i1dzqwkqfya77xpql27bjyfr4ysm5366i6d86fyg4";
    };
    
    cargoSha256 = "01sgajv00qfjm45r5bhr9dllmdsx23i6zp3p5cmqpjrdl6yqzdf2";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
