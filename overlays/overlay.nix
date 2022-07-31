with import <nixpkgs> {
  overlays = [
    (import (fetchTarball "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"))
  ];
};

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
  rust-analyzer-unwrapped = super.rust-analyzer-unwrapped.overrideAttrs (drv: rec {
    version = "2022-07-25";

    doCheck = false;
    doInstallCheck = false;

    # temp
    patches = [];

    src = super.fetchFromGitHub {
      owner = "rust-analyzer";
      repo = "rust-analyzer";
      rev = version;
      sha256 = "sha256-WFtdMN7WH5twFZEfBqpgc9PMCMHpgJnZyipDSPfui3U=";
    };

    cargoDeps = drv.cargoDeps.overrideAttrs (super.lib.const {
      name = "rust-analyzer-vendor.tar.gz";
      inherit src;
      outputHash = "sha256-f6Z0JGgRIeuAZPSkOWyvEOv7uozbwoBBDQv451+KUa8=";
    });
  });

  # Remove libXNVCtrl dependency so we don't have to pull in
  # the LTS kernel
  mangohud = (super.mangohud.override {
    libXNVCtrl = "";
  }).overrideAttrs (oldAttrs: {
    mesonFlags = oldAttrs.mesonFlags or [] ++ [
      "-Dwith_xnvctrl=disabled"
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
  helix = withRustNative super.helix;
  just = withRustNative super.just;

  #nushell = withRustNative (super.nushell.overrideAttrs (oldAttrs: rec {
  #  doCheck = false;
  #}));

  starship = withRustNativeAndPatches super.starship [ ./patches/starship.patch ];

  ripgrep = withRustNativeAndPatches super.ripgrep [ ./patches/ripgrep.patch ];

  mpv = withNativeAndFlags (super.mpv-unwrapped.override {
    vapoursynthSupport = true;
  }) [ "-O3" "-flto" ];

  vapoursynth-plugins = super.buildEnv {
    name = "vapoursynth-plugins";
    paths = [ super.vapoursynth-mvtools ];
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
