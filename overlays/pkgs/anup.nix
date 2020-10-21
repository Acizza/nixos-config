{ rustPlatform, fetchFromGitHub, stdenv, pkgconfig, sqlite, xdg_utils }:

rustPlatform.buildRustPackage rec {
    name = "anup-${version}";
    version = "c2abebd6f07d6009537efe1d2935c3aa7cfbf56a";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "anup";
      rev = version;
      sha256 = "TQJIaByQ5qsqnMcJXv/zXz19MTJIA7uZWl0liwS3E4U=";
    };
    
    cargoSha256 = "P2M0JfhYGnBNY310NVFP3K4KrG0Tv7XVomWQnXhFR2s=";
    
    buildInputs = [ stdenv.cc pkgconfig sqlite.dev xdg_utils ];
    
    meta = with stdenv.lib; {
      license = licenses.agpl3;
      platforms = platforms.linux;
    };
}
