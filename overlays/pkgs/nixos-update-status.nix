{ rustPlatform,
  lib,
  fetchFromGitHub,
  stdenv,
  pkgconfig,
}:

rustPlatform.buildRustPackage rec {
    pname = "nixos-update-status";
    version = "076be7d5890db711bc429ea9d3ce66b8476dad2e";
    
    src = fetchFromGitHub {
      owner = "Acizza";
      repo = "nixos-update-status";
      rev = version;
      sha256 = "oaRKZWETZ7VzLumIO1XwSzq/MW1MSe7r7S/Gp59p3go=";
    };
    
    cargoSha256 = "YwbF7oODv5hFI+h+mmJNEvApUcucJcRUEVX3C3PxWIU=";
    
    buildInputs = [ stdenv.cc.cc pkgconfig ];
    
    meta = with lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
