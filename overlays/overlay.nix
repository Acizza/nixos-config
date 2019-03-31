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
        vulkanDevVersion = "418.49.04";

        # The Vulkan developer drivers don't have their own build for tools like
        # nvidia-settings, so all we need to do is override the main driver
        src =
          let
            versionStr = builtins.replaceStrings ["."] [""] vulkanDevVersion;
          in
            super.fetchurl {
              url = "https://developer.nvidia.com/vulkan-beta-${versionStr}-linux";
              sha256 = "0cg5wj1snxav31s4nxkpk2wlcqa7fy3wn9isg0dahinwagxjfm8g";
            };
      });
    });

    # Wine staging with esync + FAudio
    wine = ((super.wine.override {
      # Note: we cannot set wineRelease to staging here, as it will no longer allow us
      # to use overrideAttrs
      wineBuild = "wineWow";

      # https://github.com/NixOS/nixpkgs/issues/28486#issuecomment-324859956
      gstreamerSupport = false;
    }).overrideAttrs (oldAttrs: {
      version = "4.5";
      NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";

      # This saves a decent amount of build time
      configureFlags = oldAttrs.configureFlags or [] ++ [ "--disable-tests" ];

      ## TODO: the following overrides can be removed when the upstream Wine version is >= 4.3
      buildInputs = oldAttrs.buildInputs ++ [ self.faudio self.faudio_32 ];

      mono = super.fetchurl rec {
        url = "http://dl.winehq.org/wine/wine-mono/4.8.0/wine-mono-4.8.0.msi";
        sha256 = "0y47mfjkb2viraqrvi8qpjn2935sra81h3l4bvaag737s7zmj0c9";
      };
    })).overrideDerivation (drv: {
      name = "wine-wow-${drv.version}-staging-esync";

      src = super.fetchurl {
        url = "https://dl.winehq.org/wine/source/4.x/wine-${drv.version}.tar.xz";
        sha256 = "1dy1v27cw9vp2xnr8y4bdcvvw5ivcgpk2375jgn536csbwaxgwjz";
      };

      buildInputs =
        let
          toPackages = pkgNames: pkgs:
            map (pn: super.lib.getAttr pn pkgs) pkgNames;

          toBuildInputs = pkgArches: archPkgs:
            super.lib.concatLists (map archPkgs pkgArches);

          mkBuildInputs = pkgArches: pkgNames:
            toBuildInputs pkgArches (toPackages pkgNames);

          build-inputs = pkgNames: extra:
            (mkBuildInputs drv.pkgArches pkgNames) ++ extra;
        in
          (build-inputs [ "perl" "utillinux" "autoconf" "libtxc_dxtn_s2tc" ] drv.buildInputs)
            ++ [ self.esyncPatches self.git ];

      postPatch = with super.lib; let
        staging = super.fetchFromGitHub {
          sha256 = "18xpha7nl3jg7c24cgbncciyyqqb6svsyfp1xk81993wnl6r8abs";
          owner = "wine-staging";
          repo = "wine-staging";
          rev = "v${drv.version}";
        };

        extraEsyncPatch = if versionAtLeast drv.version "4.5" then super.fetchpatch {
          name = "esync-no_kernel_obj_list.patch";
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-no_kernel_obj_list.patch";
          sha256 = "1yjcyawhcyqr4jxsbc9cficyyxznnibbfhkidm4y1p4xjmp0m3yy";
        } else super.fetchpatch {
          name = "esync-no_alloc_handle.patch";
          url = "https://raw.githubusercontent.com/Tk-Glitch/PKGBUILDS/master/wine-tkg-git/wine-tkg-patches/esync-no_alloc_handle.patch";
          sha256 = "0x4aljyywp267b7jx4509hiz8p4zvp79hmkf3pwapxdqihxvzfzp";
        };
      in ''
        # staging patches
        echo "applying staging patches"

        patchShebangs tools
        cp -r ${staging}/patches .
        chmod +w patches
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all \
            -W xaudio2-revert \
            -W xaudio2_7-CreateFX-FXEcho \
            -W xaudio2_7-WMA_support \
            -W xaudio2_CommitChanges
        cd ..

        # esync patches
        echo "applying esync patchset"

        for patch in ${self.esyncPatches}/share/esync/*.patch; do
          git apply -C1 --verbose < "$patch"
        done

        echo "applying extra esync patch"
        patch -Np1 < "${extraEsyncPatch}"
      '';
    });

    # Latest version of RPCS3 + compilation with clang
    rpcs3 = (super.rpcs3.override {
      waylandSupport = false;
      alsaSupport = false;

      stdenv = super.llvmPackages_latest.stdenv;
    }).overrideAttrs (oldAttrs: rec {
      name = "rpcs3-${version}";

      gitVersion = "7916-f15eb88";
      version = "0.0.6-${gitVersion}";

      src = super.fetchgit {
        url = "https://github.com/RPCS3/rpcs3";
        rev = "f15eb88f59fbd872a0dd58fedcc8add5f16b6b68";
        sha256 = "12dxy5pvrs6025chkjsr89pbmf5ryhd1spd9sh19nmfx58zb3j7g";
      };

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

    soulseekqt = super.soulseekqt.overrideDerivation (old: rec {
        buildInputs = old.buildInputs ++ [ super.makeWrapper ];

        phases = "unpackPhase patchPhase installPhase fixupPhase postFixupPhase";

        postFixupPhase = ''
            wrapProgram "$out/bin/SoulseekQt" \
                --prefix QT_PLUGIN_PATH : ${super.qt5.qtbase}/${super.qt5.qtbase.qtPluginPrefix}
        '';
    });

    ### Modifications to make some packages run as fast as possible

    awesome = super.awesome.overrideDerivation (old: rec {
        stdenv = super.llvmPackages_latest.stdenv;
        NIX_CFLAGS_COMPILE = "-O3 -march=native -flto";
    });

    lua = super.lua.overrideDerivation (old: rec {
        stdenv = super.gcc8Stdenv;
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
    });

    mpv = super.mpv.overrideDerivation (old: rec {
        stdenv = super.llvmPackages_latest.stdenv;
        NIX_CFLAGS_COMPILE = "-O3 -march=native -flto";
    });

    alacritty = super.alacritty.overrideAttrs (old: rec {
        patches = old.patches ++ [ ./patches/alacritty.patch ];
        RUSTFLAGS = "-C target-cpu=native";
    });

    ripgrep = super.ripgrep.overrideAttrs (old: rec {
        patches = old.patches ++ [ ./patches/ripgrep.patch ];
        RUSTFLAGS = "-C target-cpu=native";
    });

    ### Custom packages

    anup = (super.callPackage ./pkgs/anup.nix { }).overrideAttrs (old: rec {
        RUSTFLAGS = "-C target-cpu=native";
    });

    bcnotif = (super.callPackage ./pkgs/bcnotif.nix { }).overrideAttrs (old: rec {
        RUSTFLAGS = "-C target-cpu=native";
    });

    wpfxm = (super.callPackage ./pkgs/wpfxm.nix { }).overrideAttrs (old: rec {
        RUSTFLAGS = "-C target-cpu=native";
    });

    nixup = (super.callPackage ./pkgs/nixup.nix { }).overrideAttrs (old: rec {
        RUSTFLAGS = "-C target-cpu=native";
    });

    dxvk = (super.callPackage ./pkgs/dxvk {
      winePackage = self.wine;
    }).overrideDerivation (old: rec {
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

    esyncPatches = super.callPackage ./pkgs/esync-patches.nix {
      wine = self.wine;
    };
}
