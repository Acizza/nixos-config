{ rustPlatform, fetchFromGitHub, stdenv, sqlite }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "f5718f0565e18a2b2b5c06dd2f2178b708cde7f9";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "0wkhivqrz703978fh7hy9yryhpz8klmxgandp1qkais815sckjq4";
    };
    
    cargoSha256 = "18nzqdaa42p6xz6cvrhcw1ww3ysawd3zr8nx3j6fjsr83ig9fg51";
    
    buildInputs = [ stdenv.cc.cc sqlite.dev ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
