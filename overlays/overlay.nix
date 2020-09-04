self: super: let
  applyNativeFlags = stdenv: stdenv //
    { mkDerivation = args: stdenv.mkDerivation (args // {
        NIX_CFLAGS_COMPILE = toString (args.NIX_CFLAGS_COMPILE or "") + " -march=znver1";
        NIX_ENFORCE_NO_NATIVE = false;

        allowSubstitutes = false;
      });
    };

  nativeStdenv = applyNativeFlags super.stdenv;
  llvmNativeStdenv = applyNativeFlags super.llvmPackages_latest.stdenv;

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
    RUSTFLAGS = old.RUSTFLAGS or "" + " -Ctarget-cpu=znver1 -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
  });

  withRustNativeAndPatches = pkg: patches: withRustNative (pkg.overrideAttrs (old: {
    patches = old.patches or [] ++ patches;
  }));
in {
  qemu = withLLVMNative (super.qemu.override {
    hostCpuOnly = true;
    smbdSupport = true;
  });

  sudo = super.sudo.override {
    withInsults = true;
  };

  linuxPackages_5_8 = super.linuxPackages_5_8.extend (lself: lsuper: rec {
    rtl8821ce = lsuper.rtl8821ce.overrideAttrs (old: rec {
      src = super.fetchFromGitHub {
        owner = "tomaspinho";
        repo = "rtl8821ce";
        rev = "26e3caf94061f12997f3cd73bb635b7db238763c";
        sha256 = "1skazfmaighar8x2wnfpcchnl28ylmkh6cc9ds3iwy2jfn4swlss";
      };
    });
  });

  waybar = withLLVMNativeAndFlags (super.waybar.override {
    pulseSupport = true;
    mpdSupport = false;
    nlSupport = false;
  }) [ "-O3" ];

  redshift = super.redshift.overrideAttrs (oldAttrs: rec {
    pname = "redshift-wlr";
    version = "2019-04-17";

    src = super.fetchFromGitHub {
      owner = "minus7";
      repo = "redshift";
      rev = "eecbfedac48f827e96ad5e151de8f41f6cd3af66";
      sha256 = "0rs9bxxrw4wscf4a8yl776a8g880m5gcm75q06yx2cn3lw2b7v22";
    };
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

  ### Modifications to make some packages run as fast as possible

  alacritty = withRustNativeAndPatches super.alacritty [ ./patches/alacritty.patch ];

  nushell = withRustNativeAndPatches (super.nushell.overrideAttrs (oldAttrs: rec {
    doCheck = false;
  })) [ ./patches/nushell.patch ];

  ripgrep = withRustNativeAndPatches super.ripgrep [ ./patches/ripgrep.patch ];

  mpv = withLLVMNativeAndFlags super.mpv-unwrapped [ "-O3" "-flto" ];
  vapoursynth = withLLVMNativeAndFlags super.vapoursynth [ "-O3" "-flto" ];
  vapoursynth-mvtools = withLLVMNativeAndFlags super.vapoursynth-mvtools [ "-O3" "-flto" ];

  vapoursynth-plugins = super.buildEnv {
    name = "vapoursynth-plugins";
    paths = [ self.vapoursynth-mvtools ];
    pathsToLink = [ "/lib" ];
  };

  ### Custom packages

  nixup = withRustNative (super.callPackage ./pkgs/nixup.nix { });
}
