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
        wine = pkgs.wine.override {
            wineBuild = "wineWow";
            wineRelease = "staging";
        };
    };
  };
  
  environment = {
    systemPackages = with pkgs; [
        # Core Applications
        firefox
        termite
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
        wine
        gnome3.gnome-system-monitor
        gnome3.gedit
        gnome3.eog
        veracrypt
        
        # Misc Applications
        ripgrep # Improved version of grep
        bat # Improved version of cat
        psmisc # killall
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
      
      variables.PATH = "~/.cargo/bin";
      variables.TERM = "termite";
  };
  
  programs = {
    fish.enable = true;
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

        dpi = 161;
        videoDrivers = [ "nvidiaBeta" ];
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
    extraGroups = [ "wheel" "networkmanager" ];
    shell = "/run/current-system/sw/bin/fish";
  };

  system.stateVersion = "18.03";
}
