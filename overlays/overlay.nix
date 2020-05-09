self: super: let
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

  withNativeAndFlags = withStdenvAndFlags super.stdenv;
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

  # Latest Wine staging with fsync and Proton patches from GloriousEggroll.
  # When Wine is updated, changed patches should be checked for at https://github.com/GloriousEggroll/proton-ge-custom/blob/proton-ge-5/patches/protonprep.sh
  wine = let
    patch = name: sha256:
      # fetchpatch produces invalid patches(https://github.com/NixOS/nixpkgs/issues/37375)
      super.fetchurl {
        url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/proton-ge-5/patches/${name}.patch";
        inherit sha256;
      };
  in ((super.wine.override {
    # Note: we cannot set wineRelease to staging here, as it will no longer allow us
    # to use overrideAttrs
    wineBuild = "wineWow";

    gstreamerSupport = false;
    netapiSupport = false;
    cupsSupport = false;
    gphoto2Support = false;
    saneSupport = false;
    openclSupport = false;
    gsmSupport = false;
  }).overrideAttrs (oldAttrs: rec {
    version = "5.7";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      # TODO: revert to "wine-${version}" for Wine 5.8
      rev = "28ec2795186c7db83637b3b17e4fa95095ebb77d";
      sha256 = "1m4l1w0ls2vqz62s82rs3khidsqz9m8vs20pz1pxv4bn9fabfm0k";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      # TODO: revert to "v${version}" for Wine 5.8
      rev = "69a4e4baa2679972b1170a95cb9b86d08a493b54";
      sha256 = "1lwf128hzw5jz5ssd02f5jc48s87ms8fhf1isaanypj0zvgxcvxn";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: {
    name = "wine-wow-${drv.version}-staging";

    buildInputs = drv.buildInputs ++ [
      super.git
      super.perl
      super.utillinux
      super.autoconf
      super.python3
      super.perl
    ];

    protonPatches = [
      (patch "proton/proton-use_clock_monotonic" "000bpjyclz93xfybvwxgpfk2s8fkxh125sjrxijijryaxgq1khvj")
      (patch "proton/proton-amd_ags" "0phhvka6rzrxl3i44w4y97c6sphsif0zh4v7iw3izg2nak2rmhi9")
      (patch "proton/proton-FS_bypass_compositor" "0n8w2yrdrg9nfnnis50jnax5xh7yxvx0zw1kgg782n9mxjr2j0x1")
      (patch "wine-hotfixes/winevulkan-childwindow" "1hnc413100ggsq4pxad0ih2n51p435kkzn5bv642mf8dmsh0yk1l")
      (patch "proton/proton-fsync_staging" "1ws2skavabpy8x151hw88mwlplyhr0x7693shk98hcp6g5h5yi8f")
      (patch "proton/proton-fsync-spincounts" "0q0nm98xvpy5i0963giwsjrv3fy28g2649v7yivyvpv7is91w0pb")
      (patch "proton-hotfixes/wine-winex11.drv_Calculate_mask_in_X11DRV_resize_desktop" "09swin3v9wryrm7v19cls7kaha969ihn650qbhjfz62qj3ksklg9")
      (patch "proton/valve_proton_fullscreen_hack-staging" "1bm49g3m3ad80xn5id79zm27xcp4dhgcqzl59kksd5np252plkb7")
      (patch "proton/proton-LAA_staging" "1dhgxwv2cgp9mm1wikidvxyxcakv5para4m5x57d6xq2z4p84aza")
      (patch "proton-hotfixes/proton-staging_winex11-MWM_Decorations" "0950gflsn6i7cdgbbmwnz6x9icgyxvrmi0cphd4y2w5jbmqplmhg")
      (patch "proton/proton-protonify_staging" "1f0p3b4q3rjvgs9dap0jzs0w65bba7p41qrh926rlniam3rk270q")
      (patch "proton/proton-pa-staging" "1ixh8gbiqdn0nf1gyzxyni83s3969d7l21inmnj1bwq0shhwnbyv")
      (patch "proton/proton-vk-bits-4.5" "1wv9w2lpsw97y3442zjg1vmjpg7pvv74g0piiz7aid2732ib3him")
      (patch "proton/proton_fs_hack_integer_scaling" "0c6732hr68fxkpabvj14qs1zia0mfjh6gp58xqr9v6ca9k8gc2j7")
      (patch "proton/proton-winevulkan" "16725iy8sgvvm0kzwhja55f3kikwahl7lnngdizxy8jhlfdmwhdb")
      (patch "wine-hotfixes/user32-Set_PAINTSTRUCT_fErase_field_depending_on_the_last_WM_ERASEBKGND_result" "0lkivn0lq2f8ph0qwq76p8n51bwkbqmh43nczzlw5fzvikirsz5v")
      (patch "wine-hotfixes/ntdll-Use_the_free_ranges_in_find_reserved_free_area" "1i9a7psh5f7mh7d0qxw38394xnayrs7q6chsb9dwnmdi9i1lmhjb")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.139";

        stagingRevertsPatch = patch "wine-hotfixes/staging-44d1a45-localreverts" "0gs3gxiqz87jskbcvwzb1k1kf3hb66qrary3pd2vipiqah8j0f9b";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "192jvrvgqm1141g5w7bdxyb6kyrfnm03lyyy20afqbbfwcnss5ln";
        };
      in ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/
        patch -Np1 < "${stagingRevertsPatch}"
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W server-Desktop_Refcount \
          -W ws2_32-TransmitFile \
          -W winex11.drv-mouse-coorrds \
          -W winex11-MWM_Decorations \
          -W winex11-_NET_ACTIVE_WINDOW \
          -W winex11-WM_WINDOWPOSCHANGING \
          -W winex11-key_translation \
          -W user32-rawinput-mouse \
          -W user32-rawinput-nolegacy \
          -W user32-rawinput-mouse-experimental \
          -W user32-rawinput-hid \
          -W dinput-SetActionMap-genre \
          -W dinput-axis-recalc \
          -W dinput-joy-mappings \
          -W dinput-reconnect-joystick \
          -W dinput-remap-joystick \
          -W ntdll-avoid-fstatat
        cd ..

        echo "applying Proton patches.."

        for patch in $protonPatches; do
          echo "applying ''${patch}"
          patch -Np1 < "$patch"
        done

        echo "applying custom patches.."

        # Fixes X-Plane 11 not launching with Mesa
        # https://gitlab.freedesktop.org/mesa/mesa/issues/106
        patch -Np1 < ${./patches/wine_xplane.patch}

        # confirm that Wine's vulkan version matches our set one
        localVulkanVersion=$(grep -oP "VK_XML_VERSION = \"\K(.+?)(?=\")" ./dlls/winevulkan/make_vulkan)

        if [ -z "$localVulkanVersion" ]; then
          echo "error: failed to detect Wine Vulkan version"
          exit 1
        fi

        if [[ "$localVulkanVersion" != "${vulkanVersion}" ]]; then
          echo error: detected Wine vulkan version of $localVulkanVersion
          echo .. currently set vulkan version is ${vulkanVersion}
          exit 1
        fi

        patchShebangs ./dlls/winevulkan/make_vulkan
        patchShebangs ./tools/make_requests

        substituteInPlace ./dlls/winevulkan/make_vulkan --replace \
          "vk_xml = \"vk-{0}.xml\".format(VK_XML_VERSION)" \
          "vk_xml = \"${vkXmlFile}\""

        ./dlls/winevulkan/make_vulkan
        ./tools/make_requests
        autoreconf -f
      '';
  });

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
  });

  the-powder-toy = withLLVMNativeAndFlags super.the-powder-toy [ "-O3" "-flto" ];

  arc-theme = super.arc-theme.overrideAttrs (oldAttrs: {
    version = "20200417";

    src = super.fetchFromGitHub {
      owner = "jnsh";
      repo = "arc-theme";
      rev = "0779e1ca84141d8b443cf3e60b85307a145169b6";
      sha256 = "1ddyi8g4rkd4mxadjvl66wc0lxpa4qdr98nbbhm5abaqfs2yldd4";
    };

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

    meta = oldAttrs.meta // {
      broken = false;
    };
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

  qbittorrent = super.qbittorrent.overrideAttrs (oldAttrs: rec {
    NIX_CFLAGS_COMPILE = oldAttrs.NIX_CFLAGS_COMPILE or "" +
      " -O3 -flto -march=native";
  });

  faudio = withNativeAndFlags super.faudio [ "-O3" ];
  vkd3d = withNativeAndFlags super.vkd3d [ "-O3" ];

  ### Custom packages

  anup = withRustNative (super.callPackage ./pkgs/anup.nix { });
  bcnotif = withRustNative (super.callPackage ./pkgs/bcnotif.nix { });
  wpfxm = withRustNative (super.callPackage ./pkgs/wpfxm.nix { });
  nixup = withRustNative (super.callPackage ./pkgs/nixup.nix { });
  nixos-update-status = withRustNative (super.callPackage ./pkgs/nixos-update-status.nix { });

  dxvk = super.callPackage ./pkgs/dxvk {};
}
