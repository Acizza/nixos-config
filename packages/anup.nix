with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "71e2d49624e3b7a4db38f03b89d28dc5d8fe9b33";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "1h4yya3jjwdjvqc93a42v04z3834b5a97n5nrz8nzjh3wi0ib58n";
    };
    
    cargoSha256 = "03k9n9hzaz970hsl4ca3r8ykwivfcg5rvhim8nfjgsbfq96rwbnx";
    
    depsBuildBuild = [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
