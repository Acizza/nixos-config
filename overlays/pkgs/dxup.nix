{ multiStdenv,
  fetchFromGitHub,
  pkgs,
  stdenv,
  fetchurl,
  writeScript,
  unzip,
}:

let
  # Revision comes from the d3d9-dev branch
  version = "2e0d97ae741f3fd260a87ff0d97e3e2be3ec03b2";
  pipelineJob = "58";

  setup_dxup = writeScript "setup_dxup" ''
    #!${stdenv.shell}
    winetricks --force @out@/share/dxup/setup_dxup_d3d9.verb
  '';
in
  multiStdenv.mkDerivation {
    name = "dxup-${version}";

    src = fetchurl {
      url = "https://git.froggi.es/joshua/dxup/-/jobs/${pipelineJob}/artifacts/download";
      sha256 = "03jfa5i01amxmln2y0i88jpn6v1snckv4s2zj2zlizsl8ma54cjc";
    };

    buildInputs = [ unzip ];

    phases = "unpackPhase installPhase fixupPhase";

    unpackPhase = ''
      unzip $src
      tar xvf build/dxup-d3d9-dev.${version}.tar.gz
    '';

    installPhase =
      let
        dxupRoot = "dxup-d3d9-dev.${version}";
      in ''
        mkdir -p $out/bin/
        mkdir -p $out/share/dxup

        cp -r ${dxupRoot}/{x32,x64} $out/share/dxup/
        cp ${dxupRoot}/setup_dxup_d3d9.verb $out/share/dxup/setup_dxup_d3d9.verb
      '';

    fixupPhase = ''
      substitute ${setup_dxup} $out/bin/setup_dxup --subst-var out
      chmod +x $out/bin/setup_dxup
    '';
    
    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = [ licenses.mit ];
    };
  }
