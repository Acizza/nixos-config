{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "0666637013515de497be39e9589748eb893a8649";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "1jyjrqlmv9znlyrpsysiddkrrghcxl0xd8dib45bbf8zgbwa2gws";
    };
    
    cargoSha256 = "0hzps9n91k4rzl7xjjipvh22h0ii432113ldcry9zl2n8a0gjsz7";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
