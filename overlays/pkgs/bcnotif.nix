{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "31d010ca36c028b20bb5169c66113a66da5295d8";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "058gm6ibp4lwcrgx684d5pqvz3bgq4c4dqbm92s00ddp2ykr9fra";
    };
    
    cargoSha256 = "1gar2wdkv4bs9jrcyw9ksbc73ns2a9c4cml18rjrd70lkw4lr5c1";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
