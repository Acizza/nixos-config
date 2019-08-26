{ multiStdenv,
  fetchFromGitHub,
  pkgs,
  stdenv,
  meson,
  ninja,
  glslang,
  wine,
}:

let
  version = "0.20";
in
  # Note: D9VK builds its own copy of DXVK, but in this implementation we're only using the
  # D3D9 library it produces. This may cause problems if the DXVK version used does not match
  # the D9VK one.
  # That also means that DXVK must be installed separately in a prefix if D9VK is going to be used.
  multiStdenv.mkDerivation {
    name = "d9vk-${version}";

    src = fetchFromGitHub {
      owner = "Joshua-Ashton";
      repo = "d9vk";
      rev = "${version}";
      sha256 = "1bnay1ljddhclzslizv68mh7fgwb3f95fmr1kjxj15hq83gklvv9";
    };

    buildInputs = [ meson ninja glslang wine ];
    patches = [ ./only_copy_d3d9_dll.patch ../../patches/dxvk_fix_setup_script_hang.patch ];

    phases = "unpackPhase patchPhase buildPhase installPhase fixupPhase";

    buildPhase =
      let
        builder = ./builder.sh;
      in ''
        source ${builder}
        build_d9vk 64
        build_d9vk 32
      '';

    installPhase = ''
      cp setup_dxvk.sh $out/share/d9vk/setup_d9vk
      chmod +x $out/share/d9vk/setup_d9vk

      mkdir -p $out/bin/
      ln -s $out/share/d9vk/setup_d9vk $out/bin/setup_d9vk
    '';

    fixupPhase = ''
      substituteInPlace $out/share/d9vk/setup_d9vk --replace \
        "#!/bin/bash" \
        "#!${stdenv.shell}"
    '';
    
    meta = with stdenv.lib; {
      platforms = platforms.linux;
      licenses = [ licenses.zlib licenses.png ];
    };
  }
