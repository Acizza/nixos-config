{ rustPlatform, fetchFromGitHub, pkgs, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "bcnotif-${version}";
    version = "1643020b234f9be5ef7500063c183155d31b9a6e";
    
    src = fetchFromGitHub {
        owner = "Acizza";
        repo = "bcnotif";
        rev = "${version}";
        sha256 = "0a1yra8ajn0x6744yjz0zn7xph45wnjglbvl9mjb51nn3n0ylb5j";
    };
    
    cargoSha256 = "1d1d7vhgyh8apfh22fmi9rg1ipjqc7r21mml8rq8srwxaykw3hg5";
    
    nativeBuildInputs = with pkgs; [ pkgconfig ];
    buildInputs = with pkgs; [ dbus.dev sqlite.dev ];
    
    meta = with stdenv.lib; {
        license = licenses.agpl3;
        platforms = platforms.linux;
    };
}
