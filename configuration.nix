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

    # Prevents some Wine games from crashing
    kernelParams = [ "clearcpuid=514" ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
    };

    cleanTmpDir = true;
    kernelPackages = pkgs.linuxPackages_5_8;

    kernelPatches = let
      # For Wine
      fsync = rec {
        name = "v5.8-fsync";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux58-tkg/linux58-tkg-patches/0007-v5.8-fsync.patch";
          sha256 = "AdEgDFobjOgxDwmgmq57M034zSiuM4WFEERgk0X/plI=";
        };
      };
    in [ fsync ];
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
  ];

  nix = {
    maxJobs = 16;
    package = pkgs.nixUnstable;

    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

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
      vscode-with-extensions
      git
      qbittorrent
      rustup
      wine
      gnome3.gnome-system-monitor
      gnome3.eog
      veracrypt
      mullvad-vpn
      nushell
      sshfs
      duperemove
      compsize
        
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
      puddletag
      cargo-outdated
      cargo-bloat
      tokei
      spotify
      nodejs-14_x
      steam
      rust-analyzer
      anki
      ntfs3g

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
      #nixos-update-status
      vapoursynth-plugins
    ];

    shells = with pkgs; [ nushell ];

    variables = {
      TERM = "alacritty";
      RADV_PERFTEST = "aco";
      PATH = [ "/home/jonathan/.cargo/bin/" ];
    };
  };
  
  programs = {
    fish.enable = true;
    adb.enable = true;
    firejail.enable = true;
    gnupg.agent.enable = true;

    fuse.userAllowOther = true;

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
    btrfs.autoScrub.enable = true;
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

        # General
        "www.google-analytics.com"
        "ssl.google-analytics.com"
        "www.googletagmanager.com"
        "www.googletagservices.com"
        "api.facepunch.com"
        "files.facepunch.com"
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
        stdenv = if !pkgs.stdenv.is32bit then
          pkgs.impureUseNativeOptimizations pkgs.llvmPackages_latest.stdenv
        else
          # Using LLVM for 32-bit builds requires us to build GCC and LLVM, which isn't very nice
          pkgs.stdenv;
      }).overrideAttrs (oldAttrs: rec {
        version = "20.2.0";

        src = pkgs.fetchgit {
          url = "https://gitlab.freedesktop.org/mesa/mesa.git";
          # 08-04-20
          rev = "b98dd704894713b5f0b8fa2c1b52c0b970e9f89b";
          sha256 = "0v7av0mxbjcd8d2kl7pfbnrldyv8kyfmz9ixpdyimgq71s0ngw2k";
        };

        patches = let
          tail = (builtins.tail oldAttrs.patches);
        in (pkgs.lib.take 1 tail) ++ [
          ./overlays/patches/disk_cache-include-dri-driver-path-in-cache-key.patch
        ] ++ (pkgs.lib.drop 3 tail);
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
