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

  rust-analyzer-unwrapped = withRustNativeAndPatches (super.rust-analyzer-unwrapped.override rec {
    version = "2020-08-24";
    rev = version;
    sha256 = "zrY+YrMoL9bZ4Jxn/0t5RYYRCOLYyXzkfXmWgjPUBYc=";
    cargoSha256 = "ffiv0etVYFtOTFxy3aGxLZzUDdMC3FP89aqTZAcx+5g=";
    doCheck = false;
  }) [ ./patches/rust-analyzer.patch ];

  vscode-with-extensions = super.vscode-with-extensions.override {
    vscode = super.vscodium;

    vscodeExtensions = with super.vscode-extensions; [
      bbenoist.Nix
      matklad.rust-analyzer
    ] ++ super.vscode-utils.extensionsFromVscodeMarketplace [
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

  # Latest Wine staging with Proton patches from GloriousEggroll.
  wine = ((super.wine.override {
    wineRelease = "unstable";
    wineBuild = "wineWow";

    cupsSupport = false;
    gphoto2Support = false;
    saneSupport = false;
    openclSupport = false;
    gsmSupport = false;
    gstreamerSupport = false;
    vkd3dSupport = false;
    mingwSupport = true;
  }).overrideAttrs (oldAttrs: rec {
    baseVersion = "6.0";
    version = "${baseVersion}-rc1";
    geVersion = "${baseVersion}-GE-rc1";

    src = super.fetchFromGitHub {
      owner = "wine-mirror";
      repo = "wine";
      rev = "wine-${version}";
      sha256 = "lgz/xESykMKNLJX05RCWRzgoN6xOfGaduEfT+tFs3p0=";
    };

    staging = super.fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "e015f0590c1cc0136dd3038466c7a7484aeba5bc";
      sha256 = "X/UgT+Mg79DGkCrU9Ghfia0wO50KKgqDKdQW5eMPjK4=";
    };

    # Temp
    patches = [];

    NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
  })).overrideDerivation (drv: let
    repoPath = path: sha256: super.fetchurl {
      url = "https://raw.githubusercontent.com/GloriousEggroll/proton-ge-custom/${drv.geVersion}/${path}";
      inherit sha256;
    };

    patchAbsPath = path: repoPath "${path}.patch";

    patch = name: patchAbsPath "patches/${name}";
    hotfix = name: patch "wine-hotfixes/${name}";
  in {
    name = "wine-wow-${drv.version}-staging-ge";

    nativeBuildInputs = drv.nativeBuildInputs ++ [
      super.git
      super.perl
      super.utillinux
      super.autoconf
      super.python3
      super.perl
    ];

    protonPatches = let
      game = name: patch "game-patches/${name}";
      proton = name: patch "proton/${name}";

      # Need this for VK_VALVE_mutable_descriptor extension
      vulkanPatch = super.fetchurl {
        name = "proton-winevulkan-nofshack.patch";
        url = "https://raw.githubusercontent.com/Frogging-Family/wine-tkg-git/master/wine-tkg-git/wine-tkg-patches/proton/proton-winevulkan-nofshack.patch";
        sha256 = "tyc4xTfByJCTfTTcpjMOOkkIy36L/kDsRY1WG3A0Fns=";
      };
    in [
      (game "skse64_fix" "5Ee8+iihJbywcbQ/gaIU/Be/HLzagGxLVt27cBGHkpQ=")

      (proton "01-proton-use_clock_monotonic" "GXnngxXWDoh5TZ5A4H7kccML1bqoc6OUfD+s36/S0TY=")
      (proton "02-proton-FS_bypass_compositor" "oQMpsuw1WYHOezPwD/ru/sBeurISFB2tdTa93LIXHFk=")
      # Fails to apply
      #(proton "03-proton-fsync_staging" "dmyL+5b/ha52j8gMBmqfioB2nZY0sv89CdtVIm4ydBM=")
      (proton "04-proton-LAA_staging" "DxWXCWI4MCSA6rLTn+yEXtcIRP1qOCbGBwCltVP9XC0=")
      (proton "10-proton-protonify_staging" "AZdzxtokq6PW2VgnhDmYn+OP/Fq/nfdTJ2pBzYbDEhE=")
      (proton "11-proton-pa-staging" "csc5wD6aSo/JlvxuOYwrJ+RIVeEQi4r0r6fqCyHusBQ=")
      (proton "13-proton-sdl_joy" "gKERlnU4JdXGI3fV0Yk/Eo9mNQOTupeMfarmok5sMko=")
      (proton "14-proton-sdl_joy_2" "TjxhbUb4i8yzrnE8OPdpo5n77VG1Sv+5PPn3eEC1gcI=")
      (proton "15-proton-gamepad-additions" "1wISrj8sE8480ZPVUQhPudSrfBSUoBkglPVyJnyaCkg=")
      vulkanPatch
      (proton "18-proton-amd_ags" "JhJc7DygOmzVUUBxt9/PnKGdJ36jCj03YhCR4N1J83E=")
      (proton "19-proton-msvcrt_nativebuiltin" "9tfc3TM8ZA3tadFv5wmhY+6GvW70fJuJupWfQh76A0Q=")
      (proton "20-proton-atiadlxx" "TY2ir2b1wyzdBFn1xQUcqbar/Ro/+l4VWxpQUnUHyR4=")
      (proton "25-proton-rdr2-fixes" "c3qhlZl3erY0yqwvA+8iUXydqYofD6kIgDHKQc+FVI8=")

      (hotfix "winevulkan-childwindow" "5nDvZUILS4yQ4OiXXkemK1kWzMB8YGA9AEbhf2BIjdg=")
    ];

    reverts = let
      commit = hash: sha256: super.fetchurl {
        url = "https://github.com/wine-mirror/wine/commit/${hash}.patch";
        inherit sha256;
      };
    in [
      (commit "da7d60bf97fb8726828e57f852e8963aacde21e9" "06/uIQCmp9m48G1y1QKBh/8qrbweo1LJT/eK+YENEwI=")
      (commit "bd27af974a21085cd0dc78b37b715bbcc3cfab69" "fmxVQe7cWN2Ffsu3jKAMmV6r7Cp5sgbsJ3Ca3iN09Ls=")
    ];

    postPatch =
      let
        vulkanVersion = "1.2.164";

        vkXmlFile = super.fetchurl {
          name = "vk-${vulkanVersion}.xml";
          url = "https://raw.github.com/KhronosGroup/Vulkan-Docs/v${vulkanVersion}/xml/vk.xml";
          sha256 = "iFI9R7dGfNeRWs0Z+j7Y0T0g3DXagC8gh11lqQlxqjE=";
        };

        spatialAudioPatch = super.fetchurl {
          name = "spatial-audio.patch";
          url = "https://github.com/ValveSoftware/wine/commit/85d049746cd99a66fd646d5f97ba76b603bed0cd.diff";
          sha256 = "+EG5yT4eQIVRw6WO8HNrQ47QogUsCbdfl3+ouK9/SjI=";
        };
      in ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w -R patches/

        for revert in $reverts; do
          echo "!! applying revert ''${revert}"
          patch -NRp1 < "$revert"
        done

        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
          -W dinput-SetActionMap-genre \
          -W dinput-axis-recalc \
          -W dinput-joy-mappings \
          -W dinput-reconnect-joystick \
          -W dinput-remap-joystick \
          -W winex11-MWM_Decorations \
          -W winex11-_NET_ACTIVE_WINDOW \
          -W winex11-WM_WINDOWPOSCHANGING
        cd ..

        echo "applying Proton patches.."

        for patch in $protonPatches; do
          echo "!! applying ''${patch}"
          patch -Np1 < "$patch" || true
        done

        patch -Np1 < "${spatialAudioPatch}"

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

  ox = withRustNative (super.callPackage ./pkgs/ox.nix { });

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
