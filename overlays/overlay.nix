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
        gitVersion = "7619-dbd4814";

        src = super.fetchgit {
          url = "https://github.com/RPCS3/rpcs3";
          rev = "dbd48145840d7ff0ef6be5b2c41368ba09d0b5d2";
          sha256 = "1r8ysh157bvgv5lidnklsdhppqxmqblrlkmw0mnbyszhrc8zhqpv";
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
        version = "93.3";

        src = super.fetchFromGitHub {
          owner = "simtr";
          repo = "The-Powder-Toy";
          rev = "v93.3";
          sha256 = "1bg1y13kpqxx4mpncxvmg8w02dyqyd9hl43rwnys3sqrjdm9k02j";
        };

        patches = [];

        NIX_CFLAGS_COMPILE = "-march=native";
    });

    # Custom packages
    dxvk = (super.callPackage ./pkgs/dxvk {
        winePackage = super.wineWowPackages.staging;
    }).overrideDerivation (old: rec {
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
    });

    anup = (super.callPackage ./pkgs/anup.nix { }).overrideAttrs (old: rec {
        RUSTFLAGS = "-C target-cpu=native";
    });

    bcnotif = (super.callPackage ./pkgs/bcnotif.nix { }).overrideAttrs (old: rec {
        RUSTFLAGS = "-C target-cpu=native";
    });

    protonvpn-cli = super.callPackage ./pkgs/protonvpn-cli.nix { };

    # The following overrides are to make some packages run as fast as possible
    awesome = super.awesome.overrideDerivation (old: rec {
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
    });

    lua = super.lua.overrideDerivation (old: rec {
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
    });

    mpv = super.mpv.overrideDerivation (old: rec {
        NIX_CFLAGS_COMPILE = "-O3 -march=native";
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
