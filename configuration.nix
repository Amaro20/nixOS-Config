# NixOS configuration — Plasma 6 desktop with gaming setup
# (Intel CPU + AMD GPU, 8GB RAM, zram swap)
#
# NOTE: replace placeholders before use:
#   - networking.hostName
#   - users.users.<username>
#   - time.timeZone
#   - ./assets/<your-wallpaper>.png

{ config, lib, pkgs, ... }:

let
  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "sddm-breeze-custom";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/breeze-custom
      cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/. \
        $out/share/sddm/themes/breeze-custom/
      cp ${./assets/wallpaper.png} \
        $out/share/sddm/themes/breeze-custom/background.png
      sed -i 's|^background=.*|background=background.png|' \
        $out/share/sddm/themes/breeze-custom/theme.conf || \
      echo "background=background.png" >> \
        $out/share/sddm/themes/breeze-custom/theme.conf
    '';
  };
in

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;
  networking.hostName = "nixos-desktop"; # CHANGE ME
  networking.networkmanager.enable = true;
  time.timeZone = "Etc/UTC"; # CHANGE ME to your timezone

  # Ports needed for localsend
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  services.desktopManager.plasma6.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze-custom";
    extraPackages = [ sddmTheme ];
    settings = {
      Theme = {
        CursorTheme = "breeze_cursors";
      };
    };
  };

  # zram swap tuned for 8GB systems: keep swap fast (RAM-backed, compressed)
  # so high swappiness doesn't cause disk-style thrashing.
  # memoryPercent bumped 50 -> 60 for more headroom on a tight 8GB system.
  # zstd compresses better than the default lz4 (slightly more CPU cost,
  # worth it on a RAM-constrained dual-core machine).
  zramSwap = {
    enable = true;
    memoryPercent = 60;
    algorithm = "zstd";
  };

  services.flatpak.enable = true;
  services.thermald.enable = true;

  # NOTE on Baloo (KDE's file indexer): there's no NixOS module option
  # to disable it system-wide — it's a per-user Plasma setting. Disable
  # it with `balooctl6 disable` (or via System Settings > Search >
  # File Search) after rebuilding. It's a known background RAM/CPU
  # hog and worth turning off on this hardware.

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
  };
  services.pipewire.extraConfig.pipewire."99-low-power" = {
    "context.properties" = {
      "resample.quality" = 2;
    };
  };

  security.sudo.wheelNeedsPassword = true;

  users.users.youruser = { # CHANGE ME
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
    ];
  };

  programs.firefox.enable = true;

  # Steam + gaming-related settings grouped together
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamemode = {
    enable = true;
    enableRenice = true; # Keeps high CPU priority for smooth frame pacing
    settings = {
      general = {
        # Prevents GameMode from fighting with power-profiles-daemon over governor naming
        desiredgov = "none";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_vendor = "amd";
        # Tells your AMD GPU to dynamically scale clocks instead of forcing max speed
        amd_performance_level = "auto";
      };
    };
  };

  programs.dconf.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Intel CPU (iGPU video decode) + AMD discrete GPU hybrid graphics setup
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      mesa
    ];
  };

  hardware.amdgpu.initrd.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Hybrid graphics note: you have both an Intel iGPU and AMD dGPU.
  # This config already uses Mesa RADV (not AMDVLK) for the AMD GPU,
  # which is the lighter/recommended driver — no change needed there.
  # To keep idle/desktop work on the lighter Intel iGPU and reserve the
  # AMD dGPU for games, launch demanding apps with:
  #   DRI_PRIME=1 %command%
  # as a per-game Steam launch option, or `DRI_PRIME=1 <app>` from a terminal.

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    tree
    unzip
    p7zip
    kitty
    kdePackages.kate
    kdePackages.dolphin
    kdePackages.qtstyleplugin-kvantum
    kdePackages.plasma-systemmonitor
    kdePackages.sddm-kcm
    sddmTheme
    vulkan-tools
    mangohud
    pavucontrol
    fastfetch
    prismlauncher
    vesktop
    localsend
  ];

  qt.enable = true;
  qt.platformTheme = "kde";

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.kdePackages.xdg-desktop-portal-kde # Add this for Plasma 6 compatibility
    ];
    config.common.default = "*";
  };

  environment.etc."xdg/kitty/kitty.conf".text = ''
    cursor_shape block
    cursor_blink_interval 0
    cursor_trail 1
    cursor_trail_decay 0.1 0.4
  '';

  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";
  boot.loader.grub.configurationLimit = 2;

  # High swappiness is intentional here: swap is zram (RAM-backed, compressed),
  # not disk, so aggressive swapping doesn't cause the usual disk-thrashing
  # slowdown. This is a common tuning choice for 8GB systems.
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
  };

  # NOTE: stateVersion should match the NixOS release you FIRST installed
  # with — do not bump this when you upgrade channels.
  system.stateVersion = "26.05";
}
