{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  fileSystems = let
    btrfsSSD = compressLevel: [
      "ssd"
      "compress-force=zstd:${compressLevel}"
      "autodefrag"
      "noatime"
      "nodiratime"
    ];
  in {
    "/".options = btrfsSSD "3";
    "/home".options = btrfsSSD "6";
    "/media".options = btrfsSSD "6";
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    supportedFilesystems = [ "btrfs" ];

    # Fixes sway randomly not being able to start with amdgpu
    # https://bbs.archlinux.org/viewtopic.php?pid=1873238#p1873238
    initrd.kernelModules = [ "drm" ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
    };

    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_5_11;

    kernelPatches = let
      # For Wine
      fsync = rec {
        name = "v5.11-fsync";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux-tkg-patches/5.11/0007-v5.11-fsync.patch";
          sha256 = "2hHSMHtr4B0bZ1zehOJL1NMgVFgOT+gS+TDb3IgS3x4=";
        };
      };

      futex2 = rec {
        name = "v5.11-futex2";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/sirlucjan/kernel-patches/master/5.11/futex2-dev-trunk-patches-v4/0001-futex2-resync-from-gitlab.collabora.com.patch";
          sha256 = "a/5TL1OLTC7WILIKA1Vprwdgp2mo7tf3VCukyACdvcI=";
        };
      };

      enableFutex2 = {
        name = "futex2-config";
        patch = null;
        extraConfig = ''
          FUTEX2 y
        '';
      };
    in [ fsync futex2 enableFutex2 ];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";

    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];

    inputMethod.enabled = "ibus";
    inputMethod.ibus.engines = [ pkgs.ibus-engines.mozc ];
  };

  console.keyMap = "us";
  console.font = "Lat2-Terminus16";

  time.timeZone = "America/Los_Angeles";
  
  fonts.fonts = with pkgs; [
    google-fonts
    dejavu_fonts
    noto-fonts-cjk
    vistafonts
  ];

  nix = {
    maxJobs = 16;
    package = pkgs.nixUnstable;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  nixpkgs = {
    overlays = let
      rustOverlay = import (builtins.fetchTarball
        "https://github.com/oxalica/rust-overlay/archive/master.tar.gz"
      );
    in [
      (import ./overlays/overlay.nix)
      (import ./overlays/wine.nix)
      rustOverlay
    ];

    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };
  
  environment = {
    systemPackages = let
      rust = pkgs.rust-bin.stable.latest.rust.override {
        extensions = [ "rust-src" ];
      };
    in with pkgs; [
      # Core Applications
      brave
      alacritty
      ranger
      mpv
      vscode-with-extensions
      git
      qbittorrent
      wine
      veracrypt
      mullvad-vpn
      nushell
      starship
      sshfs
      duperemove
      compsize
      rust

      # KDE Packages
      kwin-tiling
      gwenview
        
      # Misc Applications
      ripgrep # Improved version of grep
      psmisc # killall
      gnome3.networkmanagerapplet
      atool
      gnupg1
      python3
      binutils
      mediainfo
      libcaca
      highlight
      file
      pavucontrol
      winetricks
      youtube-dl
      nativeFfmpeg
      rpcs3
      the-powder-toy
      qemu
      srm
      tokei
      spotify
      nodejs-15_x
      yarn
      steam
      rust-analyzer
      anki
      ntfs3g

      # Rust packages
      cargo-outdated
      cargo-bloat
      cargo-edit

      # Compression
      unar
        
      # Themes
      arc-icon-theme
      arc-theme
      gnome3.adwaita-icon-theme

      # Custom packages
      dxvk
      vkd3d
      bcnotif
      anup
      wpfxm
      nixup
      #nixos-update-status
      vapoursynth-plugins
    ];

    shells = with pkgs; [ nushell ];

    variables = {
      TERM = "alacritty";
      PATH = [ "/home/jonathan/.cargo/bin/" ];
    };
  };
  
  programs = {
    fish.enable = true;
    adb.enable = true;
    firejail.enable = true;
    gnupg.agent.enable = true;
    criu.enable = true;

    fuse.userAllowOther = true;
  };

  services = {
    btrfs.autoScrub.enable = true;
    fstrim.enable = true;
    openssh.passwordAuthentication = false;

    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];
      dpi = 200;

      displayManager = {
        autoLogin = {
          enable = true;
          user = "jonathan";
        };

        sddm = {
          enable = true;
          autoNumlock = true;
        };
      };

      desktopManager.plasma5.enable = true;

      libinput.enable = true;
    };

    mullvad-vpn.enable = true;

    # This allows PS4 controllers to be used without root access for things like RPCS3
    udev.extraRules = ''
      KERNEL=="uinput", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:05C4.*", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:09CC.*", MODE="0666"
    '';

    earlyoom = {
      enable = true;
      freeMemThreshold = 3;
      ignoreOOMScoreAdjust = true;
    };

    chrony.enable = true;
    sshd.enable = true;
  };

  systemd.services.NetworkManager-wait-online.enable = false;

  location = {
    latitude = 38.58;
    longitude = -121.49;
  };

  networking = {
    firewall = {
      enable = true;

      # For Spotify
      allowedTCPPorts = [ 57621 ];
      allowedUDPPorts = [ 57621 ];
    };

    enableIPv6 = false;
    hostName = "jonathan-desktop";

    networkmanager.enable = true;

    hosts = {
      # Block ads / tracking from desktop applications
      # This mainly serves as a backup incase I can't use my Pi-hole
      "0.0.0.0" = [
        # Firefox
        "location.services.mozilla.com"
        "shavar.services.mozilla.com"
        "incoming.telemetry.mozilla.org"
        "ocsp.sca1b.amazontrust.com"

        # Unity games
        "config.uca.cloud.unity3d.com"
        "api.uca.cloud.unity3d.com"
        "cdp.cloud.unity3d.com"

        # Unreal Engine 4 (not sure if games actually connect to these)
        "tracking.epicgames.com"
        "tracking.unrealengine.com"

        # Redshell (game analytics)
        "redshell.io"
        "www.redshell.io"
        "api.redshell.io"
        "treasuredata.com"
        "www.treasuredata.com"
        "api.treasuredata.com"
        "in.treasuredata.com"

        # GameAnalytics
        "gameanalytics.com"
        "api.gameanalytics.com"
        "rubick.gameanalytics.com"

        # Spotify
        "apresolve.spotify.com"
        "heads4-ak.spotify.com.edgesuite.net"
        "redirector.gvt1.com"

        # Microsoft Flight Simulator
        "vortex.data.microsoft.com"
        "web.vortex.data.microsoft.com"

        # General
        "www.google-analytics.com"
        "google-analytics.com"
        "ssl.google-analytics.com"
        "www.googletagmanager.com"
        "www.googletagservices.com"
      ];

      # Aliases
      "192.168.0.100" = [ "rasp.pi" ];
      "192.168.0.102" = [ "w.laptop" ];
    };
  };

  sound.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;

    opengl = let
      # latest git version of mesa
      # TODO: enable building with b_lto
      mesaDrivers = pkgs: ((pkgs.mesa.override {
        stdenv = pkgs.impureUseNativeOptimizations (if !pkgs.stdenv.is32bit then
          pkgs.llvmPackages_latest.stdenv
        else
          # Using LLVM for 32-bit builds requires us to build GCC and LLVM, which isn't very nice
          pkgs.stdenv);

        galliumDrivers = [ "radeonsi" "virgl" "svga" "swrast" "zink" ];
      }).overrideAttrs (oldAttrs: rec {
        version = "21.0.0";

        src = pkgs.fetchgit {
          url = "https://gitlab.freedesktop.org/mesa/mesa.git";
          # 01-30-21
          rev = "205e737f51baf2958c047ae6ce3af66bffb52b37";
          sha256 = "WkGiW06wEnDHTr2dIVHAcZlWLMvacHh/m4P+eVD4huI=";
        };

        mesonFlags = oldAttrs.mesonFlags ++ [
          "-Dmicrosoft-clc=disabled"
          "-Dosmesa=true"
        ];

        # For zink driver
        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.vulkan-loader
        ];

        patches = [
          ./overlays/patches/disk_cache-include-dri-driver-path-in-cache-key.patch
        ];
      })).drivers;
    in {
      driSupport32Bit = true;

      package = mesaDrivers pkgs;
      package32 = mesaDrivers pkgs.pkgsi686Linux;
    };

    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    shell = "/run/current-system/sw/bin/fish";
  };
}
