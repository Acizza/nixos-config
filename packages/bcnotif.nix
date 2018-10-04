with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "6fc45a95f9086cd5854580a6c301b61c590a2023";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "1m6m5mcv0mq0mwjkx90fyqlj8y3sdwnvjzizxlghz2xv1zbaxvpz";
    };
    
    cargoSha256 = "10b9v8ringz4b9w7gswdfcqq3w7xsbcvs8pyg2acg7snzmp6mvcv";
    
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
