with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "4b5f9cb51e52bba898316d1920511b4b0e3502cb";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "17nlvl8kwskc9b6hd9sx3s759whjqr15n0jpjdy551ff59d61z4j";
    };
    
    cargoSha256 = "04hpczkmz9fd63yvh34h9xsgq6b8vdb1npc6n5insch6yqrawz2m";
    
    depsBuildBuild = [ pkgconfig ];
    buildInputs = [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
