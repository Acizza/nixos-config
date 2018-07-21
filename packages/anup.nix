with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "ce3daa548e63401e6433abf65030c727f8a89b1a";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "1fgkk81n5nwx8pmaz0px9w4zql33hr8snlpc10qlbldw0x33ihk3";
    };
    
    cargoSha256 = "0x5xj67w5yl38zm339rjdwlvc995yv7z18jwx1prcnpi8i4ssmm7";
    
    buildInputs = [ pkgconfig openssl.dev gcc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
