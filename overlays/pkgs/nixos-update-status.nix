{ rustPlatform,
  fetchFromGitLab,
  stdenv,
  pkgconfig,
  openssl,
}:

rustPlatform.buildRustPackage rec {
    name = "nixos-update-status-${version}";
    version = "c49c6aa9c427df45c8b93bffe41ce13f4d2f952d";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "nixos-update-status";
      rev = "${version}";
      sha256 = "0vg4dr3cw7n5j5hpx240mb8v6bgq0di7pyyasrkrqwy25dla31cy";
    };
    
    cargoSha256 = "0rwxmng86xw82prbkrw30sjmb77w3phgsywldn88vx4czq8i406f";
    
    buildInputs = [ stdenv.cc.cc pkgconfig openssl.dev ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
