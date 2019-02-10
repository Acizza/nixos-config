{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  fileSystems = {
    # SSD
    "/".options = [ "noatime" "nodiratime" "discard" ];
    "/home".options = [ "noatime" "nodiratime" "discard" ];

    # HDD
    "/media/data".options = [ "noatime" "nodiratime" "defaults" ];
  };

  boot = {
    loader.grub = {
      enable = true;
      version = 2;
      useOSProber = false;
      device = "/dev/sdb";
    };
    
    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_4_20;
  };

  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

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
      vscode
      steam
      git
      transmission-gtk
      rustup
      wineWowPackages.staging
      gnome3.gnome-system-monitor
      gnome3.eog
      veracrypt
      soulseekqt
      lollypop
        
      # Misc Applications
      ripgrep # Improved version of grep
      bat # Improved version of cat
      psmisc # killall
      pywal
      easytag
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
      winetricks
      youtube-dl
      ffmpeg
      rpcs3
      python36Packages.ds4drv
      the-powder-toy

      # Compression
      unzip
      unrar
      p7zip
      zlib
        
      # Themes
      arc-icon-theme
      arc-theme
      gnome3.adwaita-icon-theme
    ] ++ [
      # Overlay packages
      dxvk
      dxup
      bcnotif
      anup
      wpfxm
      nixup
      protonvpn-cli
    ];

    variables.PATH = [ "/home/jonathan/.cargo/bin" ];
    variables.TERM = "alacritty";
  };
  
  programs = {
    fish.enable = true;
    adb.enable = true;
  };

  services = {
    compton = {
      enable = true;
      backend = "glx";
      vSync = "opengl-swc";
        
      extraOptions = ''
        paint-on-overlay = true;

        glx-no-stencil = true;
        glx-swap-method = 1;

        unredir-if-possible = true;

        blur-background = true;
        blur-background-fixed = true;
        blur-kern = "7x7box";

        blur-background-exclude = [
            "!window_type = 'dock' &&
                !window_type = 'popup_menu' &&
                !class_g = 'Alacritty'"
        ];
      '';
    };

    redshift = {
      enable = true;
      latitude = "38.58";
      longitude = "-121.49";
      temperature.night = 2700;
    };

    xserver = {
      enable = true;
      layout = "us";
      dpi = 161;
      videoDrivers = [ "nvidiaBeta" ];

      desktopManager = {
        default = "none";
        xterm.enable = false;
      };

      displayManager.lightdm = {
        enable = true;
        autoLogin.enable = true;
        autoLogin.user = "jonathan";
      };

      windowManager = {
        awesome = {
          enable = true;
          luaModules = with pkgs.luaPackages; [
            luafilesystem
          ];
        };

        default = "awesome";
      };

      # Monitor sleep times
      serverFlagsSection = ''
        Option "BlankTime" "15"
        Option "StandbyTime" "16"
        Option "SuspendTime" "16"
        Option "OffTime" "16"
      '';
    };

    # Allows ds4drv to be ran without root
    udev.extraRules = ''
      KERNEL=="uinput", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="05c4", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:05C4.*", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="09cc", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", KERNELS=="0005:054C:09CC.*", MODE="0666"
    '';

    # This is required for lollypop to scrobble to services like last.fm
    gnome3.gnome-keyring.enable = true;

    sshd.enable = true;
  };

  networking = {
    firewall = {
      enable = true;

      # Soulseek
      allowedTCPPorts = [ 60015 60016 ];
    };

    enableIPv6 = false;
    hostName = "jonathan-desktop";

    networkmanager.enable = true;

    # Block ads / tracking from desktop applications
    # This mainly serves as a backup incase my Pi-hole fails, or if connected to a different network
    hosts."0.0.0.0" = [
      # Firefox
      "location.services.mozilla.com"
      "shavar.services.mozilla.com"
      "incoming.telemetry.mozilla.org" # This is normally disabled, but added just to be safe
      "ocsp.sca1b.amazontrust.com"

      # VS Code (https://www.reddit.com/r/privacy/comments/80d8wu/just_realised_that_visual_studio_code_sends/duvaf76/)
      "dc.services.visualstudio.com"
      "dc.trafficmanager.net"
      "vortex.data.microsoft.com"
      "weu-breeziest-in.cloudapp.net"

      # Unity Games
      "config.uca.cloud.unity3d.com"
      "api.uca.cloud.unity3d.com"

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

    pulseaudio = {
      enable = true;

      # Fix audio volume randomly raising in Spotify when playing local files
      daemon.config = {
        flat-volumes = "no";
      };
    };
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "networkmanager" "adbusers" "vboxusers"  ];
    shell = "/run/current-system/sw/bin/fish";
  };
}
