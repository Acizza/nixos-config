{ rustPlatform, fetchFromGitLab, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "3d6f1f3b8700063cf00b9fdb11450b216ba23c6a";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "0k08046xc2x99vznjvn2w1q7ijhigv32vhr9plqjc2w8zj3rnyvr";
    };
    
    cargoSha256 = "0iwpy72kdigch3b3agcplv8lh7pcijj82rg4mv0sqyl4zmrl4mjw";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
