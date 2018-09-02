with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "f00c1e02e8ee87c7e7331eca160b1d9b7555b4a1";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "anup";
        rev = "${version}";
        sha256 = "1klwms6nlgkvg1rqla9ri5qk38irpyskb2qm682qzs9sq5ial253";
    };
    
    cargoSha256 = "1inif0cnrqbylql8r26qmsvqk0z2qz3gzn8b3s411bfkdhi6a9k8";
    
    nativeBuildInputs = [ buildPackages.stdenv.cc pkgconfig ];
    buildInputs = [ openssl.dev xdg_utils ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
