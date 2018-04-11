# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  boot.loader.grub = {
      enable = true;
      version = 2;
      useOSProber = true;
      device = "/dev/sdb";

      extraEntries = ''
          menuentry "Windows 10" {
              chainloader (hd0,1)+1
          }
      '';
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Los_Angeles";
  
  fonts.fonts = with pkgs; [
      google-fonts
      dejavu_fonts
      noto-fonts-cjk
  ];

  nix.gc = {
    automatic = true;
    dates = "00:00";
  };

  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = pkgs: rec {
      polybar = pkgs.polybar.override {
        i3GapsSupport = true;
      };
    };
  };
  
  environment = {
    systemPackages = with pkgs; [
        firefox
        termite
        ranger
        polybar
        atool
        python
        unzip
        mediainfo
        libcaca
        highlight
        feh
        smplayer
        mpv
        vscode
        steam
        git
        transmission-gtk
        jq
        rustup
        gcc
        pkgconfig
        gnumake
        cmake
        binutils
        openssl
        file
        zlib
        libssh2
        notify-osd
        numlockx
        lxappearance-gtk3
        arc-icon-theme
        arc-theme
        gnome3.gnome-system-monitor
        gnome3.gedit
        gnome3.dconf
        gnome3.adwaita-icon-theme
        gnome3.dconf-editor
        gnome3.eog
        dhcpcd
        ripgrep
      ];
      
      extraOutputsToInstall = [ "dev" ];
  };
  
  #gnome3.networkmanagerapplet
  
  programs = {
    bash.enableCompletion = true;
  };

  services = {
    compton = {
        enable = true;
        vSync = "opengl-swc";
    };

    redshift = {
        enable = true;
        latitude = "38.58";
        longitude = "-121.49";
        temperature.night = 3000;
    };

    xserver = {
        enable = true;
        layout = "us";

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
            i3 = {
                enable = true;
                package = pkgs.i3-gaps;
            };

            default = "i3";
        };

        dpi = 192;
        videoDrivers = [ "nvidia" ];
    };
  };

  networking = {
      #firewall.allowedTCPPorts = [ ... ];
      #firewall.allowedUDPPorts = [ ... ];

      firewall.enable = true;
      enableIPv6 = false;
      hostName = "jonathan";
  };

  sound.enable = true;

  hardware = {
      pulseaudio.enable = true;
      opengl.driSupport32Bit = true;
      cpu.intel.updateMicrocode = true;
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
