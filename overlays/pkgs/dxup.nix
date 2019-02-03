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
  version = "8e087120950db4396c6af88d53b8eff0ff8da781";
  pipelineJob = "100";

  setup_dxup = writeScript "setup_dxup" ''
    #!${stdenv.shell}
    winetricks --force @out@/share/dxup/setup_dxup_d3d9.verb
  '';
in
  multiStdenv.mkDerivation {
    name = "dxup-${version}";

    src = fetchurl {
      url = "https://git.froggi.es/joshua/dxup/-/jobs/${pipelineJob}/artifacts/download";
      sha256 = "1f0qmnb1vl31bdbq337i8bis5rwyzqq4hm4c87rk029hig41dv7z";
    };

    buildInputs = [ unzip ];

    phases = "unpackPhase installPhase fixupPhase";

    unpackPhase = ''
      unzip $src
    '';

    installPhase = ''
      mkdir -p $out/bin/
      mkdir -p $out/share/dxup

      cp -r build/dxup-release/{x32,x64} $out/share/dxup/
      cp build/dxup-release/setup_dxup_d3d9.verb $out/share/dxup/setup_dxup_d3d9.verb
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
