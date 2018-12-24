{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "c6d61e28b4de0bf56d192d08e0e80a78d135a995";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "0l4p21d3fiyx4fz7cvzva8nf0mi2ndnmdvf9msj86izas3213cva";
    };
    
    cargoSha256 = "1pjl7wqimj7wiks57fn7sw23mk1aidajxg5vi5280c1wwyk3q0vf";
    
    nativeBuildInputs = with pkgs; [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = with pkgs; [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
