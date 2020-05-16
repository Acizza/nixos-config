{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  fileSystems = {
    "/".options = [ "noatime" "nodiratime" ];
    "/home".options = [ "noatime" "nodiratime" ];
    "/media".options = [ "noatime" "nodiratime" ];
  };

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      useOSProber = false;
      device = "/dev/sdb";
    };

    kernel.sysctl."fs.inotify.max_user_watches" = 524288;
    
    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_5_6;

    # Add fsync patch for Wine
    kernelPatches =
      let
        fsync = rec {
          name = "v5.6-fsync";
          patch = pkgs.fetchpatch {
            name = name + ".patch";
            url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/9df993642a3a87f7a4027d2e03195359b1355158/linux56-tkg/linux56-tkg-patches/0007-v5.6-fsync.patch";
            sha256 = "15zgjjn3ighh2cfgj3904z9hdbdk69z58xfyjdlj5dfh094p0kv2";
          };
        };
      in [ fsync ];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";

    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
      "ja_JP.EUC-JP/EUC-JP"
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
  ];

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = import ./overlays/overlay.nix pkgs;

    android_sdk.accept_license = true;
  };
  
  environment = {
    systemPackages = with pkgs; [
      # Core Applications
      firefox-bin
      alacritty
      ranger
      mpv
      vscodium
      git
      qbittorrent
      rustup
      wine
      gnome3.gnome-system-monitor
      gnome3.eog
      veracrypt
      mullvad-vpn
        
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
      ffmpeg
      rpcs3
      the-powder-toy
      qemu
      srm
      puddletag
      cargo-outdated
      cargo-bloat
      cargo-tree
      loc
      spotify

      # Compression
      unar
        
      # Themes
      arc-icon-theme
      arc-theme
      gnome3.adwaita-icon-theme

      # Custom packages
      dxvk
      bcnotif
      anup
      wpfxm
      nixup
      nixos-update-status
      vapoursynth-plugins
    ];

    variables.TERM = "alacritty";
    variables.RADV_PERFTEST = "aco,cswave32,gewave32,pswave32";
    variables.PATH = [ "/home/jonathan/.cargo/bin/" ];
  };
  
  programs = {
    fish.enable = true;
    adb.enable = true;
    firejail.enable = true;
    gnupg.agent.enable = true;

    sway = {
      enable = true;

      extraPackages = with pkgs; [
        xwayland
        swayidle
        waybar
        mako
        rofi
      ];

      wrapperFeatures.gtk = true;

      extraSessionCommands = ''
        export SDL_VIDEODRIVER=wayland
        export MOZ_ENABLE_WAYLAND=1
        export QT_QPA_PLATFORM=wayland-egl
        export QT_WAYLAND_FORCE_DPI=physical
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export _JAVA_AWT_WM_NONREPARENTING=1

        export GDK_DPI_SCALE=2
      '';
    };
  };

  services = {
    fstrim.enable = true;

    mingetty.autologinUser = "jonathan";

    redshift = {
      enable = true;
      temperature.night = 2400;
    };

    xserver = {
      enable = false;
      videoDrivers = [ "amdgpu" ];
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

    ntp.enable = true;
    sshd.enable = true;
  };

  location = {
    latitude = 38.58;
    longitude = -121.49;
  };

  networking = {
    firewall = {
      enable = true;

      # Open these ports when connected to a VPN
      interfaces.tun0 = {
        allowedTCPPorts = [ 5504 20546 ];
      };

      # For Spotify
      allowedTCPPorts = [ 57621 ];
      allowedUDPPorts = [ 57621 ];
    };

    enableIPv6 = false;
    hostName = "jonathan-desktop";

    networkmanager.enable = true;

    # Block ads / tracking from desktop applications
    # This mainly serves as a backup incase I can't use my Pi-hole
    hosts."0.0.0.0" = [
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

      # General
      "www.google-analytics.com"
      "ssl.google-analytics.com"
      "www.googletagmanager.com"
      "www.googletagservices.com"
      "api.facepunch.com"
      "files.facepunch.com"
    ];

    hosts."192.168.0.100" = [ "rasp.pi" ];
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
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    shell = "/run/current-system/sw/bin/fish";
  };
}
