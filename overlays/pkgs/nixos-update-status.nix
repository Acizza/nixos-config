{ rustPlatform,
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
    
    cargoSha256 = "JBC8k4AEdxi1zz93AQa/ffv59HSFlF+KRfaQVmQD0HA=";
    
    buildInputs = [ stdenv.cc.cc pkgconfig ];
    
    meta = with stdenv.lib; {
      license = licenses.asl20;
      platforms = platforms.linux;
    };
}
