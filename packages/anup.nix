with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "f26ed28ebcf377ef66f8ff26bfc827aae08434be";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "14qrzmgd4aqglq64sznz8grizqpszb5w74cv4qk0h61wlaxvnccb";
    };
    
    cargoSha256 = "1ajmz3w2hszf9q7lryxjd8bvlmnlgnc7z1p97wn0vi4j3lz97csn";
    
    depsBuildBuild = [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
