self: super: {
  qemu = super.qemu.override {
    hostCpuOnly = true;
    smbdSupport = true;
  };

  sudo = super.sudo.override {
    withInsults = true;
  };

  winetricks = super.winetricks.override {
    wine = self.wine;
  };

  # Nvidia Vulkan developer driver
  linuxPackages_5_0 = super.linuxPackages_5_0.extend (selfLinux: superLinux: {
    nvidia_x11_beta = superLinux.nvidia_x11_beta.overrideDerivation (old: rec {
      name = "nvidia-x11-${vulkanDevVersion}-${selfLinux.kernel.version}-vulkan";
      vulkanDevVersion = "418.52.05";

      # The Vulkan developer drivers don't have their own build for tools like
      # nvidia-settings, so all we need to do is override the main driver
      src =
        let
          versionStr = builtins.replaceStrings ["."] [""] vulkanDevVersion;
        in
          super.fetchurl {
            url = "https://developer.nvidia.com/vulkan-beta-${versionStr}-linux";
            sha256 = "1mfz062vn4fvgfwa9crfyqly7sxwnv40wdpxqnfvbv48y1pqrn7x";
          };
    });
  });

  # Latest Wine staging with FAudio
  wine = ((super.wine.override {
    # Note: we cannot set wineRelease to staging here, as it will no longer allow us
    # to use overrideAttrs
    wineBuild = "wineWow";

    # https://github.com/NixOS/nixpkgs/issues/28486#issuecomment-324859956
    gstreamerSupport = false;
  }).overrideAttrs (oldAttrs: rec {
    version = "4.6";

    src = super.fetchurl {
      url = "https://dl.winehq.org/wine/source/4.x/wine-${version}.tar.xz";
      sha256 = "1nk2nlkdklwpd0kbq8hx59gl05b5wglcla0v3892by6k4kwh341j";
    };

    staging = super.fetchFromGitHub {
      sha256 = "0mripibsi1p8h2j9ngqszkcjppdxji027ss4shqwb0nypaydd9w2";
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
    };

    # TODO: remove when NixOS packages FAudio and the Wine version is >= 4.3
    buildInputs = oldAttrs.buildInputs ++ [ self.faudio self.faudio_32 ];

    # This saves a bit of build time
    configureFlags = oldAttrs.configureFlags or [] ++ [ "--disable-tests" ];

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: {
    name = "wine-wow-${drv.version}-staging";

    buildInputs = drv.buildInputs ++ [ super.perl super.utillinux super.autoconf super.libtxc_dxtn_s2tc ];

    postPatch = ''
      # staging patches
      patchShebangs tools
      cp -r ${drv.staging}/patches .
      chmod +w patches
      cd patches
      patchShebangs gitapply.sh
      ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W xaudio2-revert \
          -W xaudio2_7-CreateFX-FXEcho \
          -W xaudio2_7-WMA_support \
          -W xaudio2_CommitChanges
      cd ..
    '';
  });

  # Latest version of RPCS3 + compilation with clang
  rpcs3 = (super.rpcs3.override {
    waylandSupport = false;
    alsaSupport = false;

    stdenv = super.llvmPackages_latest.stdenv;
  }).overrideAttrs (oldAttrs: rec {
    name = "rpcs3-${version}";

    commit = "2119566da711f6b031fa4d62a3aab1bc614584d8";
    gitVersion = "7930-${builtins.substring 0 7 commit}";
    version = "0.0.6-${gitVersion}";

    src = super.fetchgit {
      url = "https://github.com/RPCS3/rpcs3";
      rev = "${commit}";
      sha256 = "0z10c62sndasr9z2mmsnxgqgll6n43f5i2hdyb451q5sxlr6bmim";
    };

    # https://github.com/NixOS/nixpkgs/commit/b11558669ebc7472ecaaaa7cafa2729a22b37c17
    # RPCS3 no longer detects Vulkan due to the above commit
    buildInputs = oldAttrs.buildInputs ++ [ super.vulkan-headers ];

    cmakeFlags = oldAttrs.cmakeFlags ++ [
      "-DUSE_DISCORD_RPC=OFF"
      "-DUSE_NATIVE_INSTRUCTIONS=ON"
    ];

    patches = oldAttrs.patches or [] ++ [ ./patches/rpcs3_clang.patch ];

    preConfigure = ''
      cat > ./rpcs3/git-version.h <<EOF
      #define RPCS3_GIT_VERSION "${gitVersion}"
      #define RPCS3_GIT_BRANCH "HEAD"
      #define RPCS3_GIT_VERSION_NO_UPDATE 1
      EOF
    '';
  });

  the-powder-toy = (super.the-powder-toy.override {
    stdenv = super.llvmPackages_latest.stdenv;
  }).overrideAttrs (oldAttrs: rec {
    name = "the-powder-toy-${version}";
    version = "94.1";

    src = super.fetchFromGitHub {
      owner = "simtr";
      repo = "The-Powder-Toy";
      rev = "v${version}";
      sha256 = "0w3i4zjkw52qbv3s9cgcwxrdbb1npy0ka7wygyb76xcb17bj0l0b";
    };

    buildInputs = oldAttrs.buildInputs ++ [ super.SDL2 ];

    NIX_CFLAGS_COMPILE = "-O3 -march=native";
  });

  # lollypop seems to need glib-networking in order to make HTTP(S) requests
  lollypop = super.lollypop.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [ super.glib-networking ];
  });

  soulseekqt = super.soulseekqt.overrideAttrs (oldAttrs: {
    buildInputs = oldAttrs.buildInputs ++ [ super.makeWrapper ];

    fixupPhase = oldAttrs.fixupPhase or "" + ''
      wrapProgram "$out/bin/SoulseekQt" \
        --prefix QT_PLUGIN_PATH : ${super.qt5.qtbase}/${super.qt5.qtbase.qtPluginPrefix}
    '';
  });

  vscode = super.vscode.overrideAttrs (oldAttrs: rec {
    src = super.fetchurl {
      url = "https://github.com/VSCodium/vscodium/releases/download/${oldAttrs.version}/VSCodium-linux-x64-${oldAttrs.version}.tar.gz";
      sha256 = "05xhxwd2dqx3r18wjmz482a0llaink4hwv02qypq1qr72rad747z";
    };

    unpackPhase = ''
      tar xvf ${src}
    '';

    patchPhase = oldAttrs.patchPhase or "" + ''
      mv bin/vscodium bin/code
    '';
  });

  ### Modifications to make some packages run as fast as possible

  awesome = (super.awesome.override {
    stdenv = super.llvmPackages_latest.stdenv;
  }).overrideAttrs (_: {
    NIX_CFLAGS_COMPILE = "-O3 -march=native -flto";
  });

  lua = (super.lua.override {
    stdenv = super.gcc8Stdenv;
  }).overrideAttrs (_: {
    NIX_CFLAGS_COMPILE = "-O3 -march=native";
  });

  mpv = (super.mpv.override {
    vapoursynthSupport = true;
    stdenv = super.llvmPackages_latest.stdenv;
  }).overrideAttrs (oldAttrs: {
    NIX_CFLAGS_COMPILE = "-O3 -march=native -flto";
  });


  vapoursynth = (super.vapoursynth.override {
    stdenv = super.llvmPackages_latest.stdenv;
  }).overrideAttrs (oldAttrs: {
    NIX_CFLAGS_COMPILE = "-O3 -march=native -flto";
  });

  vapoursynth-mvtools = (super.vapoursynth-mvtools.override {
    stdenv = super.llvmPackages_latest.stdenv;
  }).overrideAttrs (_: {
    NIX_CFLAGS_COMPILE = "-O3 -march=native -flto";
  });

  vapoursynth-plugins = super.buildEnv {
    name = "vapoursynth-plugins";
    paths = [ self.vapoursynth-mvtools ];
    pathsToLink = [ "/lib" ];
  };

  alacritty = super.alacritty.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [] ++ [ ./patches/alacritty.patch ];
    RUSTFLAGS = "-C target-cpu=native";
  });

  ripgrep = super.ripgrep.overrideAttrs (oldAttrs: {
    patches = oldAttrs.patches or [] ++ [ ./patches/ripgrep.patch ];
    RUSTFLAGS = "-C target-cpu=native";
  });

  ### Custom packages

  anup = (super.callPackage ./pkgs/anup.nix { }).overrideAttrs (_: {
    RUSTFLAGS = "-C target-cpu=native";
  });

  bcnotif = (super.callPackage ./pkgs/bcnotif.nix { }).overrideAttrs (_: {
    RUSTFLAGS = "-C target-cpu=native";
  });

  wpfxm = (super.callPackage ./pkgs/wpfxm.nix { }).overrideAttrs (_: {
    RUSTFLAGS = "-C target-cpu=native";
  });

  nixup = (super.callPackage ./pkgs/nixup.nix { }).overrideAttrs (_: {
    RUSTFLAGS = "-C target-cpu=native";
  });

  dxvk = (super.callPackage ./pkgs/dxvk {
    winePackage = self.wine;
  }).overrideDerivation (old: rec {
    NIX_CFLAGS_COMPILE = "-Ofast -march=native";
  });

  d9vk = (super.callPackage ./pkgs/d9vk {
    winePackage = self.wine;
  }).overrideAttrs (oldAttrs: {
    NIX_CFLAGS_COMPILE = "-Ofast -march=native";
  });

  faudio = super.callPackage ./pkgs/faudio.nix {
    stdenv = super.llvmPackages_latest.stdenv;
  };

  faudio_32 = self.faudio.overrideDerivation (o: rec {
    stdenv = super.overrideCC
      super.stdenv
      (super.wrapClangMulti super.llvmPackages_latest.clang);
  });
}
