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

    extraModulePackages = [ pkgs.linuxPackages_5_2.rtl8821ce ];

    # This enables the touchpad
    kernelPatches = lib.singleton {
      name = "enable-gpio-amd";
      patch = null;
      extraConfig = ''
        X86_AMD_PLATFORM_DEVICE y
        GPIO_AMDPT y
        PINCTRL_AMD y
      '';
    };

    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_5_2;
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";

    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];

    inputMethod.enabled = "ibus";
    inputMethod.ibus.engines = [ pkgs.ibus-engines.mozc ];
  };

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
      deluge
      rustup
      gnome3.eog
      veracrypt
      #soulseekqt
      lollypop
        
      # Misc Applications
      ripgrep # Improved version of grep
      psmisc # killall
      pywal
      gnome3.networkmanagerapplet
      feh
      atool
      gnupg1
      python3
      numlockx
      binutils
      mediainfo
      libcaca
      highlight
      file
      notify-osd
      pavucontrol
      youtube-dl
      ffmpeg
      the-powder-toy
      srm
      kcalc
      libreoffice
      kate
      puddletag
      cargo-outdated
      cargo-bloat
      loc
      spotify

      # Compression
      unzip
      unrar
      p7zip
        
      # Themes
      arc-icon-theme
      arc-theme
      gnome3.adwaita-icon-theme

      # Custom packages
      #dxvk
      #d9vk
      bcnotif
      #anup
      #wpfxm
      nixup
      vapoursynth-plugins
    ];

    variables.TERM = "alacritty";
  };
  
  programs = {
    fish.enable = true;
    adb.enable = true;
    firejail.enable = true;

    # lollypop needs this in order to save settings
    dconf.enable = true;
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

    plex = {
      enable = true;
      openFirewall = true;
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

      displayManager.sddm = {
        enable = true;
        autoLogin.enable = true;
        autoLogin.user = "wendy";
      };

      libinput = {
        enable = true;
        scrollMethod = "edge";
      };
    };

    fstrim.enable = true;
    ntp.enable = true;

    # This is required for lollypop to scrobble to services like last.fm
    gnome3.gnome-keyring.enable = true;

    sshd.enable = true;
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

      # General
      "www.google-analytics.com"
      "ssl.google-analytics.com"
      "www.googletagmanager.com"
      "www.googletagservices.com"
    ];
  };

  sound.enable = true;

  hardware = {
    cpu.amd.updateMicrocode = true;
    opengl.driSupport32Bit = true;
    pulseaudio.enable = true;
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    shell = "/run/current-system/sw/bin/fish";
  };

  users.extraUsers.wendy = {
    isNormalUser = true;
    home = "/home/wendy";
    description = "Wendy";
    extraGroups = [ "wheel" "networkmanager" "adbusers" ];
    shell = "/run/current-system/sw/bin/fish";
  };
}
