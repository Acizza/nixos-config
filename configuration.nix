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
    kernelPackages = pkgs.linuxPackages_latest;
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
    iosevka
  ];

  nix = {
    settings.max-jobs = 16;
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
      (import ./overlays/wine)
      rustOverlay
    ];

    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };
  };
  
  environment = {
    systemPackages = let
      rust = pkgs.rust-bin.stable.latest.default.override {
        extensions = [ "rust-src" ];
      };
    in with pkgs; [
      # Core Applications
      firefox-bin
      alacritty
      ranger
      helix
      lf
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
      rust-analyzer
      dxvk.out

      # Work related
      dbeaver
      postman
      insomnia
      postgresql_13
      kubectl
      google-cloud-sdk

      # KDE Packages
      kwin-tiling
      gwenview
        
      # Misc Applications
      ripgrep # Improved version of grep
      psmisc # killall
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
      yt-dlp # youtube-dl fork
      ffmpeg_5
      #the-powder-toy
      qemu
      srm
      tokei
      spotify
      nodejs-16_x
      yarn
      anki-bin
      ntfs3g
      nwjs
      just
      ngrok
      mangohud

      # Rust packages
      cargo-outdated
      cargo-bloat
      cargo-edit

      # Compression
      unar
      #ouch
      unrar
        
      # Themes
      arc-icon-theme
      arc-theme
      gnome3.adwaita-icon-theme

      # Custom packages
      vkd3d
      anup
      wpfxm
      vapoursynth-plugins
    ];

    shells = with pkgs; [ nushell ];

    variables = {
      TERM = "alacritty";
      EDITOR = "hx";
      PATH = [ "/home/jonathan/.cargo/bin/" ];
    };
  };

  virtualisation.podman.enable = true;
  
  programs = {
    fish.enable = true;
    adb.enable = true;
    gnupg.agent.enable = true;
    criu.enable = true;
    ssh.startAgent = true;

    kdeconnect.enable = true;

    fuse.userAllowOther = true;

    firejail = {
      enable = true;

      wrappedBinaries = let
        wrap = name: pkg: {
          executable = "${pkgs.lib.getBin pkg}/bin/${name}";
          profile = "${pkgs.firejail}/etc/firejail/${name}.profile";
        };
      in {
        steam = wrap "steam" pkgs.steam;
      };
    };
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

      desktopManager = {
        plasma5.enable = true;
        xterm.enable = false;
      };

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
    };

    chrony.enable = true;
    sshd.enable = true;
  };

  systemd = {
    extraConfig = ''
      DefaultTimeoutStopSec=5s
    '';

    services.NetworkManager-wait-online.enable = false;
  };

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

      # For Mullvad
      checkReversePath = "loose";
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

        # Brave
        "analytics.brave.com"
        "variations.brave.com"
        "laptop-updates.brave.com"

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

        # Windows VM
        "login.live.com"
        "settings-win.data.microsoft.com"
        "fs.microsoft.com"
        "checkappexec.microsoft.com"
        "sls.update.microsoft.com"

        # Microsoft Flight Simulator
        "vortex.data.microsoft.com"
        "web.vortex.data.microsoft.com"

        # Steam
        "googleads.g.doubleclick.net"

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
    opengl.driSupport32Bit = true;

    pulseaudio = {
      enable = true;
      support32Bit = true;
    };
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "networkmanager" "adbusers" "docker" ];
    shell = "/run/current-system/sw/bin/fish";
  };
}
