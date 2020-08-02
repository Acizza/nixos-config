{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "cd576941f6c3c6288e730afcc0a681d3d5f06abb";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0kd48va6fxabd2251w5245i5ph2yysnbfypnjfd242ixqqis7fbw";
    };
    
    cargoSha256 = "18hfki0sm6209kq4fbfis6ykb2zmq4biyl3jy5pjmaif1cs2ibpk";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
