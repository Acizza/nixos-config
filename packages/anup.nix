with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "c6e0d13712aa3771fe28b45fbc692eb2ec59024f";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "1b41y4fmaly9w2nx80yk6iqfvwfipnsvbr78y535ijyhd6225184";
    };
    
    cargoSha256 = "0x5xj67w5yl38zm339rjdwlvc995yv7z18jwx1prcnpi8i4ssmm7";
    
    depsBuildBuild = [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
