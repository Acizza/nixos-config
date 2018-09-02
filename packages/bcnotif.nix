with import <nixpkgs> {};

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "8ed652ae7cb9db8cc9e979bf8ba05033720ccfbd";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0cq3gxrrx0xl5c33qfx70pj1sar65fsb0npp7w1yr8001vdzk9f4";
    };
    
    cargoSha256 = "1pmppxbdpnya5spgl0lxy6xjyspsxzqqwjw1z0ndkrgd2c0wwpwm";
    
    nativeBuildInputs = [ pkgconfig ];
    buildInputs = [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
