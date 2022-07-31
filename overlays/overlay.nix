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
    version = "1.31.88";

    src = super.fetchurl {
      url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-browser_${version}_amd64.deb";
      sha256 = "mThs6gYZ4SW9KvAWHsB5T3ncsNzuMuZq1Jo4SAVmbuQ=";
    };
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
      bbenoist.nix
    ] ++ super.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "rust-analyzer";
        publisher = "rust-lang";
        version = "0.4.1139";
        sha256 = "sha256-A4+BAYXrYOoQkNdIx2lkQ+KMJ8r1zSpxeF38/RCCqhM=";
      }
      {
        name = "vscode-todo-plus";
        publisher = "fabiospampinato";
        version = "4.18.4";
        sha256 = "daKMeFUPZSanrFu9J6mk3ZVmlz8ZZquZa3qaWSTbSjs=";
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
        version = "3.4.1";
        sha256 = "cJ1/jfCU+Agiyi1Qdd0AfyOTzwxOEfox4vLSJ0/UKNc=";
      }
      {
        name = "tokyo-night";
        publisher = "enkia";
        version = "0.8.4";
        sha256 = "h4mE+Vv/o2MxkNb3kT9gLeDNCGQ5AvyR5nsi3cEUS5U=";
      }
      {
        name = "gitlens";
        publisher = "eamodio";
        version = "12.0.6";
        sha256 = "sha256-Q8l/GryB9iMhFnu5npUcDjWuImfrmVZF3xvm7nX/77Q=";
      }
      {
        name = "vscode-proto3";
        publisher = "zxh404";
        version = "0.5.5";
        sha256 = "Em+w3FyJLXrpVAe9N7zsHRoMcpvl+psmG1new7nA8iE=";
      }
      {
        name = "dotenv";
        publisher = "mikestead";
        version = "1.0.1";
        sha256 = "dieCzNOIcZiTGu4Mv5zYlG7jLhaEsJR05qbzzzQ7RWc=";
      }
    ];
  };

  waybar = withLLVMNativeAndFlags (super.waybar.override {
    pulseSupport = true;
    mpdSupport = false;
    nlSupport = false;
  }) [ "-O3" ];

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

  dxvk = super.dxvk.overrideAttrs (drv: let
    protonPatch = patch: sha256: super.fetchurl {
      url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/GE-Proton7-27/patches/dxvk/${patch}.patch";
      inherit sha256;
    };

  in rec {
    src = super.fetchFromGitHub {
      owner = "doitsujin";
      repo = "dxvk";
      rev = "6c5f73ac26205fe9cdb98a450e12206c6caf2510";
      sha256 = "sha256-SoRRSibxubma4VWrUrgXhAS9aQ20nkJ7Gi7omucV/Ws=";
    };

    dxvkPatches = drv.dxvkPatches ++ [
      (protonPatch "proton-dxvk_avoid_spamming_log_with_requests_for_IWineD3D11Texture2D" "sha256-CgqojCcIq2C608e0OzF94Db/IbguiTP9EDs1KChx6LA=")
      (protonPatch "proton-dxvk_add_new_dxvk_config_library" "sha256-4m+28GzxKyO8htQdR5wbFZGzaPGxqRsugEfVdopV2xM=")
      (protonPatch "2675" "sha256-8/OOjmkAfKCIfTRejMG0fXaYo8ssgPGUbJtcwh//ecM=")
      (protonPatch "dxvk-async" "sha256-6t7aNbiQIca3rxxnLCa5bR+n7NAi8vDfZFjy/KXeB3o=")
    ];

    NIX_CFLAGS_COMPILE = "-O3 -flto";
  });

  vkd3d = withNativeAndFlags (super.callPackage ./pkgs/vkd3d-proton {
    wine = self.wine;
  }) [ "-O3" ];
}
