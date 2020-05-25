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
    RUSTFLAGS = old.RUSTFLAGS or "" + " -Ctarget-cpu=native -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
  });

  withRustNativeAndPatches = pkg: patches: withRustNative (pkg.overrideAttrs (old: {
    patches = old.patches or [] ++ patches;
  }));
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

  rust-analyzer-unwrapped = withRustNative ((super.rust-analyzer-unwrapped.override rec {
    version = "2020-05-25";
    rev = version;
    sha256 = "19m07vra847ssg5xlpi5gw8m39z90pfs327xswh79x0f55zlk1ni";
    cargoSha256 = "03jfc5bsx2bsfaghhsarhsr5kxbic3nqsn46kszhz1vm3vh6x6j9";
    doCheck = false;
  }).overrideAttrs (oldAttrs: rec {
    # Remove when Rust 1.43 is merged
    patchPhase = oldAttrs.patchPhase or "" + ''
      substituteInPlace crates/ra_hir_ty/src/traits/chalk/mapping.rs --replace \
        "PlaceholderIndex { ui: UniverseIndex::ROOT, idx: usize::MAX };" \
        "PlaceholderIndex { ui: UniverseIndex::ROOT, idx: std::usize::MAX };"
    '';
  }));

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
  wine = ((super.wine.override {
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
    version = "5.9";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "1a35d8c79ibl91jz9b25fqvl42cmnwfs3zbm6s1mqim2ykfns9lk";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "1hc49crn6dd5ycg7v4rbqxncbp3svs8facm0fzxy44akslfmcxaz";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    patch = name: sha256:
      # fetchpatch produces invalid patches(https://github.com/NixOS/nixpkgs/issues/37375)
      super.fetchurl {
        url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/${drv.version}-GE-1-MF/patches/${name}.patch";
        inherit sha256;
      };
  in {
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
      (patch "proton/proton-use_clock_monotonic" "0vlx3gji487mn7kwfmrx7gaxa590bysbpd73gz96x30mgrzmzh6f")
      (patch "proton/proton-amd_ags" "0phhvka6rzrxl3i44w4y97c6sphsif0zh4v7iw3izg2nak2rmhi9")
      (patch "proton/proton-FS_bypass_compositor" "0n8w2yrdrg9nfnnis50jnax5xh7yxvx0zw1kgg782n9mxjr2j0x1")
      (patch "wine-hotfixes/winevulkan-childwindow" "1hnc413100ggsq4pxad0ih2n51p435kkzn5bv642mf8dmsh0yk1l")
      (patch "proton/proton-fsync_staging" "1ylm6x9qj8xwrr4wxzq1dbbd7dfx13d3nv3d8m1xans85i4z48yl")
      (patch "proton/proton-fsync-spincounts" "0q0nm98xvpy5i0963giwsjrv3fy28g2649v7yivyvpv7is91w0pb")
      (patch "proton-hotfixes/wine-winex11.drv_Calculate_mask_in_X11DRV_resize_desktop" "09swin3v9wryrm7v19cls7kaha969ihn650qbhjfz62qj3ksklg9")
      (patch "proton/valve_proton_fullscreen_hack-staging" "1bm49g3m3ad80xn5id79zm27xcp4dhgcqzl59kksd5np252plkb7")
      (patch "proton/proton-LAA_staging" "1dhgxwv2cgp9mm1wikidvxyxcakv5para4m5x57d6xq2z4p84aza")
      (patch "proton-hotfixes/proton-staging_winex11-MWM_Decorations" "0950gflsn6i7cdgbbmwnz6x9icgyxvrmi0cphd4y2w5jbmqplmhg")
      (patch "proton/proton-protonify_staging" "196i7jlcswd1c9bqa4990wbpc76nmlm3vqmvrrpajn2hw9b9xscl")
      (patch "proton/proton-pa-staging" "1ixh8gbiqdn0nf1gyzxyni83s3969d7l21inmnj1bwq0shhwnbyv")
      (patch "proton/proton-vk-bits-4.5" "1wv9w2lpsw97y3442zjg1vmjpg7pvv74g0piiz7aid2732ib3him")
      (patch "proton/proton_fs_hack_integer_scaling" "0c6732hr68fxkpabvj14qs1zia0mfjh6gp58xqr9v6ca9k8gc2j7")
      (patch "proton/proton-winevulkan" "0jixz54w7iha10in21b1p4zzcfps81zpahav81s5sp34avb3l3ml")
      (patch "wine-hotfixes/media_foundation_alpha" "0w68k1kxbrdkmpfqkvyyf5qlr6wamvsi3jz70axnyvy7z7mi4yny")
      (patch "wine-hotfixes/proton_mediafoundation_dllreg" "0wcrh99skvrag7j34sf519yjypcr1n431pq9kqkya14hn4jxij86")
      (patch "wine-hotfixes/user32-Set_PAINTSTRUCT_fErase_field_depending_on_the_last_WM_ERASEBKGND_result" "0lkivn0lq2f8ph0qwq76p8n51bwkbqmh43nczzlw5fzvikirsz5v")
      (patch "wine-hotfixes/winemono-update_to_5.0.1" "1g9hvagffb2pf8ip5dpvqnnk317cvwgnwllbjsl27g8y3kg43dr3")
    ];

    reverts = let
      commit = hash: sha256: super.fetchurl {
        url = "https://github.com/wine-mirror/wine/commit/${hash}.patch";
        inherit sha256;
      };
    in [
      # Proton gamepad changes
      (commit "da7d60bf97fb8726828e57f852e8963aacde21e9" "00hk1n0zk2pp9z4m58qypjnjmzw7h41dawkdy2wdk9x600hyxbyk")
      # fshack
      (commit "26b26a2e0efcb776e7b0115f15580d2507b10400" "15msa775ph399m4i9z46xzfjckmlrbvqc2rnwy70cxd4h44a2z8d")
      (commit "fd6f50c0d3e96947846ca82ed0c9bd79fd8e5b80" "1g7fi342h91ah7nb3xidyc89mrxhk2q9z7jg7jd7yk6kk1yzvpfa")
      # Time hotfix
      (commit "7cc9ccbd22511d71d23ee298cd9718da1e448dbc" "17pfznyci7ykqj6h9mzgl834ngsay3mkn01zhiydnzd3mwkibll0")
      (commit "79e3c21c3cca822efedff3092df42f9044da10fe" "0n5bcmsm445dq44alc89axzplldbxygp0nmxwgxh09bwvdq3pg7h")
      (commit "75e2f79b684f70e7184592db16d819b778d575ae" "05kv9ldim1hkqgjzydmk51jncfqii4cc3lbkiqzxsyp4nnrb21pw")
      (commit "4ccc3e52852447198a8b81fc91472bfa3b614914" "1if47f1c492xyjdqvghp827wx3mw10md4x7nynvlbb883d3ypshv")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.140";

        stagingRevertsPatch = patch "wine-hotfixes/staging-44d1a45-localreverts" "0gs3gxiqz87jskbcvwzb1k1kf3hb66qrary3pd2vipiqah8j0f9b";
        timeHotfixPatch = patch "wine-hotfixes/time_hotfix" "0rxm65wh8xpizvq8p0xplxli4i3iz57zd6nn9glk72bl0y4l0n9q";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "0x4s8y7il4f8wmsjzgpi0ljmams32zr7c08bcwdvqljndsf4myvc";
        };
      in ''
        for revert in $reverts; do
          echo "!! applying revert ''${revert}"
          patch -NRp1 < "$revert"
        done

        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/
        patch -Np1 < "${stagingRevertsPatch}"
        patch -Np1 < "${timeHotfixPatch}"
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
          -W dinput-remap-joystick
        cd ..

        echo "applying Proton patches.."

        for patch in $protonPatches; do
          echo "!! applying ''${patch}"
          patch -Np1 < "$patch" || true
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

  alacritty = withRustNative super.alacritty;
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

  dxvk = super.callPackage ./pkgs/dxvk.nix { };
}
