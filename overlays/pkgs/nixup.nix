{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "d40b337ab6e38e0825433b043e341b5922c5c7ff";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "138dz2yyn304lq6cqric27p9vfzysszxh4gj15s5n6dslapzmg6c";
    };
    
    cargoSha256 = "0xz0k6pip7pshxj05ybf60sxlmkgfvshxa6sjkfia77545lmvahg";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
