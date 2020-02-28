{ rustPlatform, fetchFromGitLab, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "wpfxm-${version}";
    version = "9d70945c2d7f2eba8dc2fe1049ec7103e2835380";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "wpfxm";
      rev = "${version}";
      sha256 = "046bnhs3r49ly5k1pjf2ll4r0whz4k1y1675h6671nqjhrw0l79z";
    };
    
    cargoSha256 = "12rkgcy43gq656am9mz72nrs6b31vz7cd8156xvi1cszg0nv4vya";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
