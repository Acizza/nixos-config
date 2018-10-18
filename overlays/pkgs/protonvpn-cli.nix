{ stdenv, fetchFromGitHub, openvpn, python, dialog, wget, sysctl, coreutils, makeWrapper }:

let
  version = "v1.1.1";
in
  stdenv.mkDerivation rec {
    name = "protonvpn-cli-${version}";

    src = fetchFromGitHub {
      owner = "ProtonVPN";
      repo = "protonvpn-cli";
      rev = "${version}";
      sha256 = "0kli5xqsprjwv8rchzgpkwl7lk4jzg5yc78qc4kjfkywnx62xbpd";
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