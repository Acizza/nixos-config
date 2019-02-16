{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "c0cccc20c35470987215a88f72a3b293394fd115";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "0wbw2xhp5j6f0sw116payjjkxfv5h6jfl9wdq33g72pf52xdnbb4";
    };
    
    cargoSha256 = "1cvkd3p278a7mld4kldjja9kplhc33jgcnihlibm8f4pvw7l1w9g";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
