self: super: let
  llvmNativeStdenv = super.impureUseNativeOptimizations super.llvmPackages_latest.stdenv;
  multiNativeStdenv = super.impureUseNativeOptimizations super.multiStdenv;

  withFlags = pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" +
        super.lib.concatMapStrings (x: " " + x) flags;
    });

  withStdenv = newStdenv: pkg:
    pkg.override { stdenv = newStdenv; };

  withStdenvAndFlags = newStdenv: pkg:
    withFlags (withStdenv newStdenv pkg);

  withNativeAndFlags = withStdenvAndFlags super.stdenv;
  with32BitNativeAndFlags = withStdenvAndFlags super.pkgsi686Linux.stdenv;
  withLLVMNative = withStdenv llvmNativeStdenv;
  withLLVMNativeAndFlags = withStdenvAndFlags llvmNativeStdenv;

  withRustNative = pkg: pkg.overrideAttrs (old: {
    RUSTFLAGS = old.RUSTFLAGS or "" + " -C target-cpu=native";
  });

  withRustNativeAndPatches = pkg: patches: pkg.overrideAttrs (old: {
    patches = old.patches or [] ++ patches;
    RUSTFLAGS = old.RUSTFLAGS or "" + " -C target-cpu=native";
  });
in {
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

  # TODO: these packages refuse to detect clang, even when the stdenv is properly set
  sway = withNativeAndFlags super.sway [ "-O3" ];
  wlroots = withNativeAndFlags super.wlroots [ "-O3" ];
  mako = withNativeAndFlags super.mako [ "-O3" ];

  waybar = (super.waybar.override {
    pulseSupport = true;
    mpdSupport = false;
    nlSupport = false;
  }).overrideAttrs (oldAttrs: rec {
    version = "97e3226801680211081abce54fe099c8b0bf5c18";

    src = super.fetchFromGitHub {
      owner = "Alexays";
      repo = "Waybar";
      rev = version;
      sha256 = "07zj7yswb0dgnsik5jnnsnq071xb10b3mf0ra0ppcbrq1m9sqnrp";
    };

    mesonFlags = oldAttrs.mesonFlags or [] ++ [
      "-Dsystemd=disabled"
    ];

    NIX_CFLAGS_COMPILE = "-O3 -march=native";
  });

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

  i3 = withLLVMNativeAndFlags super.i3 [ "-O3" ];
  rofi-unwrapped = withLLVMNativeAndFlags super.rofi-unwrapped [ "-O3" ];
  dunst = withLLVMNativeAndFlags super.dunst [ "-O3" "-flto" ];

  polybar = withLLVMNativeAndFlags (super.polybar.override {
    i3GapsSupport = true;
    pulseSupport = true;
  }) [ "-O3" ];

  # Latest Wine staging with FAudio
  wine = ((super.wine.override {
    # Note: we cannot set wineRelease to staging here, as it will no longer allow us
    # to use overrideAttrs
    wineBuild = "wineWow";

    # https://github.com/NixOS/nixpkgs/issues/28486#issuecomment-324859956
    gstreamerSupport = false;
    netapiSupport = false;
    cupsSupport = false;
    gphoto2Support = false;
    saneSupport = false;
    openclSupport = false;
    ldapSupport = false;
    gsmSupport = false;
  }).overrideAttrs (oldAttrs: rec {
    version = "4.17";

    src = super.fetchurl {
      url = "https://dl.winehq.org/wine/source/4.x/wine-${version}.tar.xz";
      sha256 = "1bmj4l84q29h4km5ab5zzypns3mpf7pizybcpab6jj47cr1s303l";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "0cb0w6jwqs70854g1ixfj8r53raln0spyy1l96qv72ymbhzc353h";
    };

    # TODO: remove when NixOS packages FAudio and the Wine version is >= 4.3
    buildInputs = oldAttrs.buildInputs ++ [ self.faudio self.faudio_32 ];

    # This saves a bit of build time
    configureFlags = oldAttrs.configureFlags or [] ++ [ "--disable-tests" ];

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: {
    name = "wine-wow-${drv.version}-staging";

    buildInputs = drv.buildInputs ++ [ super.git super.perl super.utillinux super.autoconf super.libtxc_dxtn_s2tc ];

    postPatch =
      let
        # fetchpatch produces invalid patches here (https://github.com/NixOS/nixpkgs/issues/37375)
        fsyncStagingPatch = super.fetchurl {
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/proton/fsync-staging.patch";
          sha256 = "1hndiydrx466lv994bfr4ms69pmwg5sanp18hah330mv1b31v563";
        };

        fsyncNoAllocHandlePatch = super.fetchurl {
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/proton/fsync-staging-no_alloc_handle.patch";
          sha256 = "17xaqdymqwrdg8bw612xw5kaa23mi57n6csipngk85bd4v1gffrh";
        };
      in ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w patches
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all
        cd ..

        # fsync patches
        echo "applying fsync patches.."

        patch -Np1 < "${fsyncStagingPatch}"
        patch -Np1 < "${fsyncNoAllocHandlePatch}"

        # Fixes X-Plane 11 not launching with Mesa
        # https://gitlab.freedesktop.org/mesa/mesa/issues/106
        patch -Np1 < ${./patches/wine_xplane.patch}

        # Regenerated OpenGL bindings without traces (*may* improve performance ever so slightly)
        patch -Np1 < ${./patches/wine_regen_opengl.patch}
      '';
  });

  # git version of RPCS3
  rpcs3 = (super.rpcs3.override {
    waylandSupport = false;
    alsaSupport = false;

    stdenv = super.gcc9Stdenv;
  }).overrideAttrs (oldAttrs: rec {
    name = "rpcs3-${version}";

    commit = "9dc06cef7fb8482d15483904157fec99a574f786";
    gitVersion = "8639-${builtins.substring 0 7 commit}";
    version = "0.0.7-${gitVersion}";

    src = super.fetchgit {
      url = "https://github.com/RPCS3/rpcs3";
      rev = "${commit}";
      sha256 = "1jwl3w087gf6zw2wdlqjfqzcmgsc3m4mip78k1fw607n4xiwzrai";
    };

    buildInputs = oldAttrs.buildInputs ++ [ super.vulkan-headers super.libglvnd ];

    patches = [ ./patches/rpcs3_fix_compile.patch ];

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

    # Since we disabled gnome shell support, we can remove the dependency on it
    nativeBuildInputs = super.lib.remove super.gnome3.gnome-shell oldAttrs.nativeBuildInputs;
  });

  ### Modifications to make some packages run as fast as possible

  alacritty = withRustNativeAndPatches super.alacritty [ ./patches/alacritty.patch ];
  ripgrep = withRustNativeAndPatches super.ripgrep [ ./patches/ripgrep.patch ];

  mpv = let
    mpvPkg = super.mpv.override {
      vapoursynthSupport = true;
    };
  in withLLVMNativeAndFlags mpvPkg [ "-O3" "-flto" ];

  vapoursynth = withLLVMNativeAndFlags super.vapoursynth [ "-O3" "-flto" ];
  vapoursynth-mvtools = withLLVMNativeAndFlags super.vapoursynth-mvtools [ "-O3" "-flto" ];

  vapoursynth-plugins = super.buildEnv {
    name = "vapoursynth-plugins";
    paths = [ self.vapoursynth-mvtools ];
    pathsToLink = [ "/lib" ];
  };

  ### Custom packages

  anup = withRustNative (super.callPackage ./pkgs/anup.nix { });
  bcnotif = withRustNative (super.callPackage ./pkgs/bcnotif.nix { });
  wpfxm = withRustNative (super.callPackage ./pkgs/wpfxm.nix { });
  nixup = withRustNative (super.callPackage ./pkgs/nixup.nix { });
  nixos-update-status = withRustNative (super.callPackage ./pkgs/nixos-update-status.nix { });

  dxvk = super.callPackage ./pkgs/dxvk {
    multiStdenv = multiNativeStdenv;
  };

  d9vk = super.callPackage ./pkgs/d9vk {
    multiStdenv = multiNativeStdenv;
  };

  faudio = withNativeAndFlags (super.callPackage ./pkgs/faudio.nix { }) [ "-O3" "-flto" ];
  faudio_32 = with32BitNativeAndFlags (super.pkgsi686Linux.callPackage ./pkgs/faudio.nix { }) [ "-O3" "-flto" ];
}
