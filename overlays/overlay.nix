self: super: {
    # Generic overrides
    winetricks = super.winetricks.override {
        wine = super.wineWowPackages.staging;
    };

    sudo = super.sudo.override {
      withInsults = true;
    };

    rpcs3 = (super.rpcs3.override {
        waylandSupport = false;
        alsaSupport = false;
    }).overrideDerivation (old: rec {
        gitVersion = "7802-56e24f8";

        src = super.fetchgit {
          url = "https://github.com/RPCS3/rpcs3";
          rev = "56e24f8993d70ff19f69ae0fda3f8b9db720ece4";
          sha256 = "1kc7vb4ywlpay6p5wgmaz6i2f08zjfvj3zrwp8fiyjjr7v9pmawi";
        };

        preConfigure = ''
          cat > ./rpcs3/git-version.h <<EOF
          #define RPCS3_GIT_VERSION "${gitVersion}"
          #define RPCS3_GIT_BRANCH "HEAD"
          #define RPCS3_GIT_VERSION_NO_UPDATE 1
          EOF
        '';

        cmakeFlags = [
          "-DUSE_SYSTEM_LIBPNG=ON"
          "-DUSE_SYSTEM_FFMPEG=ON"
          "-DUSE_NATIVE_INSTRUCTIONS=ON"
        ];

        # Compilation fails on GCC 7 or earlier
        stdenv = super.gcc8Stdenv;
    });

    the-powder-toy = super.the-powder-toy.overrideDerivation (old: rec {
        stdenv = super.llvmPackages_latest.stdenv;
        version = "94.1";

        src = super.fetchFromGitHub {
          owner = "simtr";
          repo = "The-Powder-Toy";
          rev = "v${version}";
          sha256 = "1bg1y13kpqxx4mpncxvmg8w02dyqyd9hl43rwnys3sqrjdm9k02j";
        };

        patches = [];

        NIX_CFLAGS_COMPILE = "-O3 -march=native";
    });

    # lollypop seems to need glib-networking in order to make HTTP(S) requests
    lollypop = super.lollypop.overrideAttrs (old: rec {
        buildInputs = old.buildInputs ++ [ super.glib-networking ];
    });

    wineWowPackages.staging = super.wineWowPackages.staging.overrideDerivation (old: rec {
        NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
    });

    soulseekqt = super.soulseekqt.overrideDerivation (old: rec {
        buildInputs = old.buildInputs ++ [ super.makeWrapper ];

        phases = "unpackPhase patchPhase installPhase fixupPhase postFixupPhase";

        postFixupPhase = ''
            wrapProgram "$out/bin/SoulseekQt" \
                --prefix QT_PLUGIN_PATH : ${super.qt5.qtbase}/${super.qt5.qtbase.qtPluginPrefix}
        '';
    });

    qemu = super.qemu.override {
        hostCpuOnly = true;
        smbdSupport = true;
    };

    # Custom packages
    dxvk = (super.callPackage ./pkgs/dxvk {
        winePackage = super.wineWowPackages.staging;
    }).overrideDerivation (old: rec {
        NIX_CFLAGS_COMPILE = "-Ofast -march=native";
    });

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

    protonvpn-cli = super.callPackage ./pkgs/protonvpn-cli.nix { };

    # The following overrides are to make some packages run as fast as possible
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
}
