{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "1e979c2614bf05761f421f3e9d27c8768b9ae40e";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "1am076wz8xmsx5rgb3f2gyq185r3k7mx72dcrr3iffw09xsc854z";
    };
    
    cargoSha256 = "1g6qz2aqpzirzsbsa8dnb3r1sprikdd94pf6kwqrvmd7hajr7yr8";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
