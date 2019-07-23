{ rustPlatform,
  fetchFromGitLab,
  stdenv,
  pkgconfig,
  openssl,
}:

rustPlatform.buildRustPackage rec {
    name = "nixos-update-status-${version}";
    version = "1c4592e53d4b8a87f13f06427e3c5b2b5403aef9";
    
    src = fetchFromGitLab {
      owner = "Acizza";
      repo = "nixos-update-status";
      rev = "${version}";
      sha256 = "0m99iz4ralq9jk9q55vkai3cln8h627r10szgp1s513d210fgcm9";
    };
    
    cargoSha256 = "05ki1lvxh6bcvi14m352sa7ilp4jqy46fl5mv97w81fx65wjbg76";
    
    buildInputs = [ stdenv.cc.cc pkgconfig openssl.dev ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
