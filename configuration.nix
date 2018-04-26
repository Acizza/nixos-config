# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];


  boot = {
    loader.grub = {
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
    
    cleanTmpDir = true;
  };

  i18n = {
    consoleFont = "Lat2-Terminus16";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";

    inputMethod.enabled = "ibus";
    inputMethod.ibus.engines = [ pkgs.ibus-engines.mozc ];
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
      curl = pkgs.curl.override {
        sslSupport = true;
      };
    };
    
    permittedInsecurePackages = [
        "mono-4.0.4.1"
    ];
  };
  
  environment = {
    systemPackages = with pkgs; [
        firefox
        termite
        ranger
        atool
        python3
        unzip
        unrar
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
        gnome3.networkmanagerapplet
        ripgrep
        google-musicmanager
        brasero
        # for killall
        psmisc
        hicolor_icon_theme
        numix-icon-theme
        pywal
        (import ./packages/anup.nix)
        (import ./packages/bcnotif.nix)
        (import ./packages/sp.nix) # Command line tool for Spotify's dbus interface
        spotify
        easytag
      ];
      
      extraOutputsToInstall = [ "dev" ];
      
      variables.PATH = "~/.cargo/bin";
  };
  
  programs = {
    bash.enableCompletion = true;
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
            blur-kern = "15,15,0.140858,0.182684,0.227638,0.272532,0.313486,0.346456,0.367879,0.375311,0.367879,0.346456,0.313486,0.272532,0.227638,0.182684,0.140858,0.182684,0.236928,0.295230,0.353455,0.406570,0.449329,0.477114,0.486752,0.477114,0.449329,0.406570,0.353455,0.295230,0.236928,0.182684,0.227638,0.295230,0.367879,0.440432,0.506617,0.559898,0.594521,0.606531,0.594521,0.559898,0.506617,0.440432,0.367879,0.295230,0.227638,0.272532,0.353455,0.440432,0.527292,0.606531,0.670320,0.711770,0.726149,0.711770,0.670320,0.606531,0.527292,0.440432,0.353455,0.272532,0.313486,0.406570,0.506617,0.606531,0.697676,0.771052,0.818731,0.835270,0.818731,0.771052,0.697676,0.606531,0.506617,0.406570,0.313486,0.346456,0.449329,0.559898,0.670320,0.771052,0.852144,0.904837,0.923116,0.904837,0.852144,0.771052,0.670320,0.559898,0.449329,0.346456,0.367879,0.477114,0.594521,0.711770,0.818731,0.904837,0.960789,0.980199,0.960789,0.904837,0.818731,0.711770,0.594521,0.477114,0.367879,0.375311,0.486752,0.606531,0.726149,0.835270,0.923116,0.980199,0.980199,0.923116,0.835270,0.726149,0.606531,0.486752,0.375311,0.367879,0.477114,0.594521,0.711770,0.818731,0.904837,0.960789,0.980199,0.960789,0.904837,0.818731,0.711770,0.594521,0.477114,0.367879,0.346456,0.449329,0.559898,0.670320,0.771052,0.852144,0.904837,0.923116,0.904837,0.852144,0.771052,0.670320,0.559898,0.449329,0.346456,0.313486,0.406570,0.506617,0.606531,0.697676,0.771052,0.818731,0.835270,0.818731,0.771052,0.697676,0.606531,0.506617,0.406570,0.313486,0.272532,0.353455,0.440432,0.527292,0.606531,0.670320,0.711770,0.726149,0.711770,0.670320,0.606531,0.527292,0.440432,0.353455,0.272532,0.227638,0.295230,0.367879,0.440432,0.506617,0.559898,0.594521,0.606531,0.594521,0.559898,0.506617,0.440432,0.367879,0.295230,0.227638,0.182684,0.236928,0.295230,0.353455,0.406570,0.449329,0.477114,0.486752,0.477114,0.449329,0.406570,0.353455,0.295230,0.236928,0.182684,0.140858,0.182684,0.227638,0.272532,0.313486,0.346456,0.367879,0.375311,0.367879,0.346456,0.313486,0.272532,0.227638,0.182684,0.140858";
            
            blur-background-exclude = [
                "!window_type = 'dock' && !window_type = 'popup_menu' && !name = 'termite'"
            ];
        '';
    };

    redshift = {
        enable = true;
        latitude = "38.58";
        longitude = "-121.49";
        temperature.night = 2800;
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
            awesome = {
                enable = true;
                luaModules = with pkgs.luaPackages; [
                    luafilesystem
                ];
            };

            default = "awesome";
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
      
      networkmanager.enable = true;
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
