with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "a629636dc011f603b2c1cef681c8ede9fea497bb";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "0jdbz80dw099ygwlx6xlcib5h703d7hcq9ldw1wwlpckc4hvzdm1";
    };
    
    cargoSha256 = "03k9n9hzaz970hsl4ca3r8ykwivfcg5rvhim8nfjgsbfq96rwbnx";
    
    depsBuildBuild = [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
