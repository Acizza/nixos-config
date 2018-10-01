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
        useOSProber = false;
        device = "/dev/sda";

        extraEntries = ''
          menuentry "Windows 10" {
              chainloader (hd0,1)+1
          }
        '';
    };
    
    cleanTmpDir = true;
    
    kernelPackages = pkgs.linuxPackages_4_18;
  };

  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

  virtualisation.virtualbox.host.enable = true;

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

  nixpkgs.config = {
    allowUnfree = true;

    packageOverrides = pkgs: rec {
        winetricks = pkgs.winetricks.override {
            wine = pkgs.wineWowPackages.staging;
        };

        alacritty = pkgs.alacritty.overrideAttrs (old: rec {
            patches = old.patches ++ [ ./patches/alacritty.patch ];
        });
    };
  };
  
  environment = {
    systemPackages = with pkgs; [
        # Core Applications
        firefox
        alacritty
        ranger
        mpv
        vscode
        steam
        git
        spotify
        transmission-gtk
        rustup
        (import ./packages/anup.nix)
        (import ./packages/bcnotif.nix)
        wineWowPackages.staging
        gnome3.gnome-system-monitor
        gnome3.gedit
        gnome3.eog
        veracrypt
        tor-browser-bundle-bin
        
        # Misc Applications
        ripgrep # Improved version of grep
        bat # Improved version of cat
        psmisc # killall
        calc
        pywal
        (import ./packages/dxvk.nix) # D3D11 -> Vulkan (for Wine)
        easytag
        gnome3.networkmanagerapplet
        feh
        lxappearance-gtk3
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
        openvpn

        # Compression
        unzip
        unrar
        p7zip
        zlib
        
        # Themes
        arc-icon-theme
        arc-theme
        gnome3.adwaita-icon-theme
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
                 !class_g = 'Termite'"
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
  };

  networking = {
      firewall = {
          enable = true;
          
          # Spotify local file sync
          allowedTCPPorts = [ 57621 ];
          allowedUDPPorts = [ 57621 1900 5353 ];
      };
      
      enableIPv6 = false;
      hostName = "jonathan-desktop";
      
      networkmanager.enable = true;

      # Block ads / tracking from desktop applications
      # This mainly serves as a backup incase my PiHole fails, or if connected to a different network
      hosts."0.0.0.0" = [
        # Spotify
        "www.googletagservices.com"
        "audio-fac.spotify.com"
        "audio4-ak.spotify.com.edgesuite.net"
        "heads4-ak.spotify.com.edgesuite.net"

        # Firefox
        "location.services.mozilla.com"
        "shavar.services.mozilla.com"
        "incoming.telemetry.mozilla.org" # This is normally disabled, but added just to be safe

        # VS Code (https://www.reddit.com/r/privacy/comments/80d8wu/just_realised_that_visual_studio_code_sends/duvaf76/)
        "dc.services.visualstudio.com"
        "marketplace.visualstudio.com"
        "dc.trafficmanager.net"
        "vortex.data.microsoft.com"
        "weu-breeziest-in.cloudapp.net"

        # General
        "www.google-analytics.com" # The X-Plane installer is known to use this
        "ssl.google-analytics.com"
        "b.scorecardresearch.com"
        "www.imrworldwide.com"
      ];
  };

  sound.enable = true;

  hardware = {
      pulseaudio.enable = true;
      opengl.driSupport32Bit = true;
      cpu.amd.updateMicrocode = true;
  };

  users.extraUsers.jonathan = {
    isNormalUser = true;
    home = "/home/jonathan";
    description = "Jonathan";
    extraGroups = [ "wheel" "networkmanager" "adbusers" "vboxusers"  ];
    shell = "/run/current-system/sw/bin/fish";
  };

  system.stateVersion = "18.03";
}
