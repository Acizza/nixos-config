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

  rust-analyzer-unwrapped = withRustNative (super.rust-analyzer-unwrapped.override rec {
    version = "2020-06-22";
    rev = version;
    sha256 = "1cxsdc4b1823i5dx7nvh584araqbhpj8lx3jc0cc8qgm9hdbphz8";
    cargoSha256 = "0gn0gmzzxwbrbv5csrqz59mk9pkj54mljf9cam75f8mx1kv6472r";
    doCheck = false;
  });

  vscode-with-extensions = super.vscode-with-extensions.override {
    vscode = super.vscodium;

    vscodeExtensions = with super.vscode-extensions; [
      bbenoist.Nix
      matklad.rust-analyzer
    ] ++ super.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "vscode-todo-plus";
        publisher = "fabiospampinato";
        version = "4.17.1";
        sha256 = "00gcv66plxalmipmbhv11b1q3dhjs81ry0k4p5313m4kbn9s7dg2";
      }
      {
        name = "graphql-for-vscode";
        publisher = "kumar-harsh";
        version = "1.15.3";
        sha256 = "1x4vwl4sdgxq8frh8fbyxj5ck14cjwslhb0k2kfp6hdfvbmpw2fh";
      }
      {
        name = "vetur";
        publisher = "octref";
        version = "0.24.0";
        sha256 = "025zf47sblcx93mymg9dfca5f9pfi8sg7a0ycsmnagnzq5l1ccjw";
      }
      {
        name = "better-toml";
        publisher = "bungcip";
        version = "0.3.2";
        sha256 = "08lhzhrn6p0xwi0hcyp6lj9bvpfj87vr99klzsiy8ji7621dzql3";
      }
    ];
  };

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
    version = "5.11";
    geVersion = "${version}-GE-1-MF";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "1xznnjfb1v2mab1ab6w2l4b2gwnrn85akngjg53jqqlff2p6nycd";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "050npck8mdck8m2rs9xn6mszzj2fv9ql80g08j2ahinf792svrid";
    };

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    patchAbsPath = path: sha256:
      # fetchpatch produces invalid patches(https://github.com/NixOS/nixpkgs/issues/37375)
      super.fetchurl {
        url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/${drv.geVersion}/${path}.patch";
        inherit sha256;
      };

    patch = name: patchAbsPath "patches/${name}";
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
      (patch "proton/proton-use_clock_monotonic" "018nlnqpg3zmfhphycfjnqrk90j895ndl5y406hziq6nd1srkqp5")
      (patch "proton/proton-amd_ags" "0phhvka6rzrxl3i44w4y97c6sphsif0zh4v7iw3izg2nak2rmhi9")
      (patch "proton/proton-FS_bypass_compositor" "0n8w2yrdrg9nfnnis50jnax5xh7yxvx0zw1kgg782n9mxjr2j0x1")
      (patch "wine-hotfixes/winevulkan-childwindow" "1hnc413100ggsq4pxad0ih2n51p435kkzn5bv642mf8dmsh0yk1l")
      # Broken in 5.10
      #(patch "proton/proton-fsync_staging" "1ylm6x9qj8xwrr4wxzq1dbbd7dfx13d3nv3d8m1xans85i4z48yl")
      #(patch "proton/proton-fsync-spincounts" "0q0nm98xvpy5i0963giwsjrv3fy28g2649v7yivyvpv7is91w0pb")
      (patch "proton/proton-LAA_staging" "1z1nii80vqa2g3ni4rv100x2j0alvashca42k4d6camfzqv86vv0")
      (patch "proton/proton-protonify_staging" "1s74690g64awgqh75g8f51fknf91rrm5swfzqxwcqfdgvvj0xr0c")
      (patch "proton/proton-pa-staging" "1ixh8gbiqdn0nf1gyzxyni83s3969d7l21inmnj1bwq0shhwnbyv")
      (patch "proton/proton-sdl_joy" "0xrlh95vrvqas53yhqp56w4r18c4p823z35smd41b4l0hc0x1dn5")
      (patch "proton/proton-sdl_joy_2" "1spafkrzyvs6m7rgw5v6jdw09qsxd7w0r5syw1rv89xm5cc26b18")
      (patch "proton/proton-gamepad-additions" "0ypswj4cvqrksw9vrf40zaimkv90amilbjqclfsxjy4vfsl3j469")
      (patch "proton/proton-vk-bits-4.5-nofshack" "1gpgpsf8rk3q9qmi4rslh9w9gs0vznpb1x744q87515a5c8djvir")
      (patch "proton/proton-winevulkan-nofshack" "031y2zzirygnlrf5gz2s45gf6310zaxm59infzr0jq97yxkf44ah")
      (patch "wine-hotfixes/media_foundation/media_foundation_wine_pending" "03jprk5dwxqfxip02hp158fpqwqbz3ndl1zzvmvxn29v6wywyxxh")
      (patch "wine-hotfixes/media_foundation/media_foundation_alpha" "0x3nijdsgvdvyq0mpv5vn120nj66sb0h0frl9h5sjpsbyfyp76jm")
      (patch "wine-hotfixes/media_foundation/proton_mediafoundation_dllreg" "0wcrh99skvrag7j34sf519yjypcr1n431pq9kqkya14hn4jxij86")
    ];

    reverts = let
      commit = hash: sha256: super.fetchurl {
        url = "https://github.com/wine-mirror/wine/commit/${hash}.patch";
        inherit sha256;
      };
    in [
      # Proton gamepad changes
      (commit "da7d60bf97fb8726828e57f852e8963aacde21e9" "00hk1n0zk2pp9z4m58qypjnjmzw7h41dawkdy2wdk9x600hyxbyk")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.142";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "1kbzqglsh4v8h9nzs7vb4n64kmna999g060b5wa7l8hnzl67z4b5";
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
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W server-Desktop_Refcount \
          -W ws2_32-TransmitFile \
          -W dinput-SetActionMap-genre \
          -W dinput-axis-recalc \
          -W dinput-joy-mappings \
          -W dinput-reconnect-joystick \
          -W dinput-remap-joystick \
          -W user32-window-activation
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

  sway = withNativeAndFlags super.sway [ "-O3" "-flto" ];
  wlroots = withNativeAndFlags super.wlroots [ "-O3" "-flto" ];
  mako = withNativeAndFlags super.mako [ "-O3" ];

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
