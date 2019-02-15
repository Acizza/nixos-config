{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "6fce698d53871e27cef85df7921c092f9605c498";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "1xj9qwyyw0nrrqbzhff5xnrki4jrkbf8p455bzshn3ysv27b2pyn";
    };
    
    cargoSha256 = "1cvkd3p278a7mld4kldjja9kplhc33jgcnihlibm8f4pvw7l1w9g";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
