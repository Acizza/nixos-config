{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "b07d08282de5dc44281eb6484d42f2d353a234f9";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "nixup";
        rev = "${version}";
        sha256 = "1wnvasfnxsc524h17vh3hbpn1bghl56rnrsdz78lpwpdb9jwhvpm";
    };
    
    cargoSha256 = "0hzps9n91k4rzl7xjjipvh22h0ii432113ldcry9zl2n8a0gjsz7";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
