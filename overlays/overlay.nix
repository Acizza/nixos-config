self: super: {
    # Generic overrides
    winetricks = super.winetricks.override {
        wine = super.wineWowPackages.staging;
    };

    sudo = super.sudo.override {
      withInsults = true;
    };

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

    ffmpeg = super.ffmpeg.overrideDerivation (old: rec {
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
