{ rustPlatform,
  fetchFromGitHub,
  stdenv,
  lib,
  pkgconfig,
  sqlite,
  xdg_utils
}:

rustPlatform.buildRustPackage rec {
    pname = "anup";
    version = "b5ed36b5ea82e99096fe9596c7eefcfe96bc8dcc";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "OnwDtiIBwwotgFecXpbM0onKhUemiRKklFtgRSQriQk=";
    };
    
    cargoSha256 = "E0VmFoqnrt1dDm220+BoiDoTVGRrcwFijIwo8t+bc5E=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
