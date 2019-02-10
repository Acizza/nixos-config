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
    
    cargoSha256 = "19bcniyv8l304r8n09ij4w2a0igcp73cxsg1r9kvykq0cqjm4rfw";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
