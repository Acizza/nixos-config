{ stdenv, fetchFromGitHub, openvpn, python, dialog, wget, sysctl, coreutils, makeWrapper }:

let
  version = "v1.1.2";
in
  stdenv.mkDerivation rec {
    name = "protonvpn-cli-${version}";

    src = fetchFromGitHub {
      owner = "ProtonVPN";
      repo = "protonvpn-cli";
      rev = "${version}";
      sha256 = "0xvflr8zf267n3dv63nkk4wjxhbckw56sqmyca3krf410vrd7zlv";
    };

    runtime_deps = [
      openvpn
      python
      dialog
      wget
      sysctl
      coreutils
    ];

    buildInputs = runtime_deps ++ [ makeWrapper ];

    phases = "unpackPhase installPhase fixupPhase";

    installPhase = ''
      mkdir -p $out/bin
      cp protonvpn-cli.sh $out/bin/protonvpn-cli
    '';

    fixupPhase = ''
      wrapProgram $out/bin/protonvpn-cli \
        --prefix PATH : ${stdenv.lib.makeBinPath runtime_deps}
    '';

    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = licenses.mit;
    };
  }