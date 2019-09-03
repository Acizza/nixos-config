{ rustPlatform, fetchFromGitLab, stdenv }:

rustPlatform.buildRustPackage rec {
    name = "nixup-${version}";
    version = "a5834e677a1c8c395c56c1505dd1761985f6f787";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "nixup";
      rev = "${version}";
      sha256 = "0dwh15dnc57350f6ggg6nf3iiwq5dd5r0mspprkpyynzzs6jriag";
    };
    
    cargoSha256 = "13dh4mmxg72dxcp9lczn0k9aawlnxq6mhfry0d7pha47ljab7d23";
    
    buildInputs = [ stdenv.cc.cc ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
