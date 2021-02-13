self: super: let
  nativeStdenv = super.impureUseNativeOptimizations super.stdenv;
  llvmNativeStdenv = super.impureUseNativeOptimizations super.llvmPackages_latest.stdenv;

  withFlags = pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" +
        super.lib.concatMapStrings (x: " " + x) flags;
    });

  withStdenv = newStdenv: pkg:
    pkg.override { stdenv = newStdenv; };

  withStdenvAndFlags = newStdenv: pkg:
    withFlags (withStdenv newStdenv pkg);

  withNativeAndFlags = withStdenvAndFlags nativeStdenv;
  withLLVMNative = withStdenv llvmNativeStdenv;
  withLLVMNativeAndFlags = withStdenvAndFlags llvmNativeStdenv;

  withRustNative = pkg: pkg.overrideAttrs (old: {
    RUSTFLAGS = old.RUSTFLAGS or "" + " -Ctarget-cpu=native -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
  });

  withRustNativeAndPatches = pkg: patches: withRustNative (pkg.overrideAttrs (old: {
    patches = old.patches or [] ++ patches;
  }));
in {
  brave = super.brave.overrideAttrs (oldAttrs: rec {
    version = "1.20.103";

    src = super.fetchurl {
      url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser_${version}_amd64.deb";
      sha256 = "4xC1sCfEc6u7wkKTTKeyHMYUmelcH2n70T/9N9MEavY=";
    };
  });

  # This override can be released on the next release
  firejail = super.firejail.overrideAttrs (oldAttrs: rec {
    version = "0.9.64";

    src = super.fetchFromGitHub {
      owner = "netblue30";
      repo = "firejail";
      rev = version;
      sha256 = "sXa33sVdo7Kd4qfT9ViP/s3G91U/Fh6Urt0FHmZZaZQ=";
    };

    patches = oldAttrs.patches or [] ++ [
      (super.fetchurl {
        name = "remove-env-vars.patch";
        url = "https://github.com/netblue30/firejail/commit/21711c8a4fd834b95fbd73767e5453c01cb4228e.patch";
        sha256 = "Dnwc6VQsm5xOOYQHpDWfeXSihyzRbp35QPtJOT4Lwdg=";
      })
    ];
  });

  qemu = withLLVMNative (super.qemu.override {
    hostCpuOnly = true;
    smbdSupport = true;
  });

  sudo = withLLVMNative (super.sudo.override {
    withInsults = true;
  });

  ibus = super.ibus.override {
    withWayland = true;
  };

  vscode-with-extensions = super.vscode-with-extensions.override {
    vscode = super.vscodium;

    vscodeExtensions = with super.vscode-extensions; [
      bbenoist.Nix
    ] ++ super.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "rust-analyzer";
        publisher = "matklad";
        version = "0.2.481";
        sha256 = "2NdiH1j7EdHHxekpHdIH7DDvpU0JsXSqBFdZI/qgaP0=";
      }
      {
        name = "vscode-todo-plus";
        publisher = "fabiospampinato";
        version = "4.18.0";
        sha256 = "OtrglGQTCxORjKWZvKbj+3SF8MRvjrZwCwZUCgWEZ0g=";
      }
      {
        name = "graphql-for-vscode";
        publisher = "kumar-harsh";
        version = "1.15.3";
        sha256 = "1x4vwl4sdgxq8frh8fbyxj5ck14cjwslhb0k2kfp6hdfvbmpw2fh";
      }
      {
        name = "better-toml";
        publisher = "bungcip";
        version = "0.3.2";
        sha256 = "08lhzhrn6p0xwi0hcyp6lj9bvpfj87vr99klzsiy8ji7621dzql3";
      }
      {
        name = "errorlens";
        publisher = "usernamehw";
        version = "3.2.4";
        sha256 = "fZZk85SF+lgH1sTCP8uWV0Oqz5xBjsvMfbNosI2rXTE=";
      }
      {
        name = "tokyo-night";
        publisher = "enkia";
        version = "0.6.7";
        sha256 = "AD+ygvrs1UYUlSAX3md+aUhAEC5TtF6c7b089Qv51+k=";
      }
      {
        name = "svelte-vscode";
        publisher = "svelte";
        version = "102.8.0";
        sha256 = "sopN6tYQiqsJ1Z/aiBOOjGckutkIQCwPGFnmw9BXN3g=";
      }
      {
        name = "prettier-vscode";
        publisher = "esbenp";
        version = "5.8.0";
        sha256 = "x6/bBeHi/epYpRGy4I8noIsnwFdFEXk3igF75y5h/EA=";
      }
      {
        name = "vscode-eslint";
        publisher = "dbaeumer";
        version = "2.1.14";
        sha256 = "bVGmp871yu1Llr3uJ+CCosDsrxJtD4b1+CR+omMUfIQ=";
      }
      {
        name = "gitlens";
        publisher = "eamodio";
        version = "11.1.3";
        sha256 = "hqJg3jP4bbXU4qSJOjeKfjkPx61yPDMsQdSUVZObK/U=";
      }
    ];
  };

  waybar = withLLVMNativeAndFlags (super.waybar.override {
    pulseSupport = true;
    mpdSupport = false;
    nlSupport = false;
  }) [ "-O3" ];

  # git version of RPCS3
  rpcs3 = (super.rpcs3.override {
    waylandSupport = true;
    alsaSupport = false;

    stdenv = llvmNativeStdenv;
  }).overrideAttrs (oldAttrs: rec {
    name = "rpcs3-${version}";

    commit = "8ca53f9c843712c25988f44761417f526fc26212";
    gitVersion = "9165-${builtins.substring 0 7 commit}";
    version = "0.0.7-${gitVersion}";

    src = super.fetchgit {
      url = "https://github.com/RPCS3/rpcs3";
      rev = "${commit}";
      sha256 = "0gmirrs8j7kzjjp01d7n1nlmjc78lcj4zdn2jk6j853spcf44jb1";
    };

    buildInputs = oldAttrs.buildInputs ++ [ super.vulkan-headers super.libglvnd ];

    cmakeFlags = oldAttrs.cmakeFlags ++ [
      "-DUSE_DISCORD_RPC=OFF"
      "-DUSE_NATIVE_INSTRUCTIONS=ON"
    ];

    preConfigure = ''
      cat > ./rpcs3/git-version.h <<EOF
      #define RPCS3_GIT_VERSION "${gitVersion}"
      #define RPCS3_GIT_BRANCH "HEAD"
      #define RPCS3_GIT_VERSION_NO_UPDATE 1
      EOF
    '';

    postInstall = let
      mlaaPatch = super.fetchurl {
        name = "patch.yml";
        url = "https://rpcs3.net/blog/wp-content/uploads/2020/common/mlaa/patch.yml";
        sha256 = "018mm3zg9zvdwqk61ixjvz6z1ky2qlxlzaqfmdqszgf4rj8yk4mg";
      };
    in oldAttrs.postInstall or "" + ''
      cp ${mlaaPatch} $out/bin/patch.yml
    '';
  });

  the-powder-toy = withLLVMNativeAndFlags super.the-powder-toy [ "-O3" "-flto" ];

  arc-theme = super.arc-theme.overrideAttrs (oldAttrs: {
    configureFlags = oldAttrs.configureFlags or [] ++ [
      "--disable-light"
      "--disable-cinnamon"
      "--disable-gnome-shell"
      "--disable-metacity"
      "--disable-unity"
      "--disable-xfwm"
      "--disable-plank"
      "--disable-openbox"
    ];
  });

  nativeFfmpeg = withLLVMNative super.ffmpeg_4;

  ### Modifications to make some packages run as fast as possible

  alacritty = withRustNativeAndPatches super.alacritty [ ./patches/alacritty.patch ];

  nushell = withRustNativeAndPatches (super.nushell.overrideAttrs (oldAttrs: rec {
    doCheck = false;
  })) [ ./patches/nushell.patch ];

  starship = withRustNativeAndPatches super.starship [ ./patches/starship.patch ];

  ripgrep = withRustNativeAndPatches super.ripgrep [ ./patches/ripgrep.patch ];

  mpv = withLLVMNativeAndFlags (super.mpv-unwrapped.override {
    vapoursynthSupport = true;
  }) [ "-O3" "-flto" ];

  vapoursynth = withLLVMNativeAndFlags super.vapoursynth [ "-O3" "-flto" ];
  vapoursynth-mvtools = withLLVMNativeAndFlags super.vapoursynth-mvtools [ "-O3" "-flto" ];

  vapoursynth-plugins = super.buildEnv {
    name = "vapoursynth-plugins";
    paths = [ self.vapoursynth-mvtools ];
    pathsToLink = [ "/lib" ];
  };

  qbittorrent = super.qbittorrent.overrideAttrs (oldAttrs: rec {
    NIX_CFLAGS_COMPILE = oldAttrs.NIX_CFLAGS_COMPILE or "" +
      " -O3 -flto -march=native";
  });

  sway = withNativeAndFlags super.sway [ "-O3" "-flto" ];
  wlroots = withNativeAndFlags super.wlroots [ "-O3" "-flto" ];
  mako = withNativeAndFlags super.mako [ "-O3" ];

  faudio = withNativeAndFlags super.faudio [ "-O3" ];

  ### Custom packages

  anup = withRustNative (super.callPackage ./pkgs/anup.nix { });
  bcnotif = withRustNative (super.callPackage ./pkgs/bcnotif.nix { });
  wpfxm = withRustNative (super.callPackage ./pkgs/wpfxm.nix { });
  nixup = withRustNative (super.callPackage ./pkgs/nixup.nix { });
  nixos-update-status = withRustNative (super.callPackage ./pkgs/nixos-update-status.nix { });

  dxvk = super.callPackage ./pkgs/dxvk.nix { };

  vkd3d = withNativeAndFlags (super.callPackage ./pkgs/vkd3d-proton {
    wine = self.wine;
  }) [ "-O3" ];
}
