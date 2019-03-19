{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "a2b5c3afb7f6dfab09d3fc5c44429b3c43f8891b";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "09ayr3qxqkl2d9yvy9wbi4dph5lc04mmqg1rxp8xx7r3yll3pdjx";
    };
    
    cargoSha256 = "1iw97f5z0k7236mycjkkz8zfkn3pj6yirp1lri1kf1m47rd51jrd";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
