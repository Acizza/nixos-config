{ rustPlatform, fetchFromGitLab, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "13b42ce79f17b0cf486addfa83eb296aa8d3b297";
    
    src = fetchFromGitLab {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "1q4ci786h7pysbg8bfkb4jnlhzj5s2z830vszdbxic0ky7f4q5ag";
    };
    
    cargoSha256 = "08lxh92yg566zgmp6kv0qx69vwsi7insbyxii7v722d7m0klcjb6";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev openssl.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.asl20;
        platforms = platforms.linux;
    };
}
