{ stdenv, writeScript, fetchFromGitHub, pkgs }:

let
  version = "v1.1.1";

  dependencies = with pkgs; [
    openvpn
    python
    dialog
    wget
    sysctl
    coreutils
  ];

  protonvpn-cli = writeScript "protonvpn-cli" ''
    #!${stdenv.shell}
    PATH=$PATH:${stdenv.lib.makeBinPath dependencies}
    exec @out@/share/protonvpn-cli.sh "$@"
  '';
in
  stdenv.mkDerivation {
    name = "protonvpn-cli-${version}";

    src = fetchFromGitHub {
      owner = "ProtonVPN";
      repo = "protonvpn-cli";
      rev = "${version}";
      sha256 = "0kli5xqsprjwv8rchzgpkwl7lk4jzg5yc78qc4kjfkywnx62xbpd";
    };

    buildInputs = dependencies;
    phases = "unpackPhase installPhase";

    installPhase = ''
        mkdir -p $out/bin $out/share

        cp protonvpn-cli.sh $out/share/protonvpn-cli.sh
        chmod +x $out/share/protonvpn-cli.sh

        substitute ${protonvpn-cli} $out/bin/protonvpn-cli --subst-var out
        chmod +x $out/bin/protonvpn-cli
    '';

    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = licenses.mit;
    };
  }