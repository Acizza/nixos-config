{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  fileSystems = {
    "/".options = [ "noatime" "nodiratime" ];
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    extraModulePackages = [ pkgs.linuxPackages_5_8.rtl8821ce ];

    kernelPatches = let
      rtl8821ceBT = rec {
        name = "rtl8821ce-bt";
        patch = ./overlays/patches/rtl8821ce-b00a.patch;
      };
    in [ rtl8821ceBT ];

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1
    '';

    # Power saving options
    kernel.sysctl = {
      "kernel.nmi_watchdog" = 0;
      "vm.laptop_mode" = 5;
    };

    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_5_8;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";

    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
  };

  console.keyMap = "us";
  console.font = "Lat2-Terminus16";

  time.timeZone = "America/Los_Angeles";
  
  fonts.fonts = with pkgs; [
    google-fonts
    dejavu_fonts
    noto-fonts-cjk
  ];

  nix = {
    distributedBuilds = true;

    buildMachines = [
      {
        hostName = "192.168.0.103";
        sshUser = "root";
        sshKey = "/root/.ssh/id_rsa";
        system = "x86_64-linux";
        speedFactor = 2;
        maxJobs = 4;
        supportedFeatures = [ "big-parallel" ]; 
      }
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = import ./overlays/overlay.nix pkgs;

    android_sdk.accept_license = true;
  };
  
  environment = {
    systemPackages = with pkgs; [
      # Core applications
      firefox-bin
      alacritty
      ranger
      mpv
      gnome3.eog
      qemu
      git
        
      # Misc applications
      psmisc # killall
      gnome3.networkmanagerapplet
      atool
      gnupg1
      binutils
      mediainfo
      libcaca
      highlight
      file
      #notify-osd
      youtube-dl
      ffmpeg
      spotify
      mullvad-vpn
      nushell
      ripgrep

      # Compression
      unar
        
      # Themes
      arc-icon-theme
      arc-theme
      gnome3.adwaita-icon-theme

      # Custom packages
      nixup
      vapoursynth-plugins
    ];

    shells = with pkgs; [ nushell ];

    variables.TERM = "alacritty";
    variables.PATH = [ "/home/jonathan/.cargo/bin/" ];
  };
  
  programs = {
    fish.enable = true;
    adb.enable = true;
    firejail.enable = true;

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
        export QT_QPA_PLATFORM=wayland
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export _JAVA_AWT_WM_NONREPARENTING=1
      '';
    };
  };

  location = {
    latitude = 38.58;
    longitude = -121.49;
  };

  services = {
    redshift = {
      enable = true;
      temperature.night = 2400;
    };

    printing = {
      enable = true;
      drivers = [ pkgs.hplip ];
    };

    xserver = {
      enable = true;
      layout = "us";
      videoDrivers = [ "amdgpu" ];

      desktopManager = {
        xterm.enable = false;
        plasma5.enable = true;
      };

      displayManager = {
        autoLogin = {
          enable = true;
          user = "wendy";
        };

        sddm.enable = true;
      };

      libinput = {
        enable = true;
        scrollMethod = "edge";
      };
    };

    fstrim.enable = true;
    chrony.enable = true;
    sshd.enable = true;
    mullvad-vpn.enable = true;

    # Allow the screen backlight to be controlled by users
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl0", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", KERNEL=="amdgpu_bl0", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    '';

    earlyoom = {
      enable = true;
      freeMemThreshold = 3;
      ignoreOOMScoreAdjust = true;
    };
  };

  powerManagement.powertop.enable = true;

  networking = {
    firewall = {
      enable = true;

      # For Spotify
      allowedTCPPorts = [ 57621 ];
      allowedUDPPorts = [ 57621 ];
    };

    enableIPv6 = false;
    hostName = "wendy-laptop";

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
      "api.redshell.io"
      "treasuredata.com"
      "api.treasuredata.com"
      "in.treasuredata.com"

      # GameAnalytics
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

      # General
      "www.google-analytics.com"
      "google-analytics.com"
      "ssl.google-analytics.com"
      "www.googletagmanager.com"
      "www.googletagservices.com"
    ];

    hosts."192.168.0.100" = [ "rasp.pi" ];
    hosts."192.168.0.103" = [ "j.desktop" ];
  };

  sound.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl.driSupport32Bit = true;

    bluetooth = {
      enable = true;

      config = {
        Policy = {
          AutoEnable = true;
        };
      };
    };

    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
    };
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "video" "networkmanager" "adbusers" ];
    shell = "/run/current-system/sw/bin/fish";

    packages = with pkgs; [
      # Core applications
      vscodium
      rustup
      veracrypt

      # Misc applications
      python3
      pavucontrol
      the-powder-toy
      srm
      cargo-outdated
      cargo-bloat
      loc
      brillo
      gnome3.gnome-system-monitor
    ];
  };

  users.extraUsers.wendy = {
    isNormalUser = true;
    home = "/home/wendy";
    description = "Wendy";
    extraGroups = [ "wheel" "video" "networkmanager" "adbusers" ];
    shell = "/run/current-system/sw/bin/fish";

    packages = with pkgs; [
      numlockx
      kcalc
      libreoffice
      kate
    ];
  };
}
