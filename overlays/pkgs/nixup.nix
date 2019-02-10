{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "4966ba930d4ba56159f5d676f2f4c66cc12f84b5";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "15658sn61wvn6zifjiyz8v6garv8qqrcsxqabjshg4xyv3yi9wm4";
    };
    
    cargoSha256 = "0hzps9n91k4rzl7xjjipvh22h0ii432113ldcry9zl2n8a0gjsz7";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
