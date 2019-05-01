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
    
    cargoSha256 = "1z0yqgl018wbjrshy7msm6r44j5ng7pln5qmkdl2i9hpy8b891a4";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
