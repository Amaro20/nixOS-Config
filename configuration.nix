# NixOS configuration — Plasma 6 desktop with gaming setup
# (Intel CPU + AMD GPU, 8GB RAM, zram swap)
#
# Tuned for low-power hardware (e.g. dual-core Intel laptop CPU with no
# Turbo Boost + an older/low-end AMD dGPU). Goal: balanced performance
# without overheating, particularly for lighter 2D games (e.g. tModLoader).
#
# >>> Before using this, replace the placeholders marked CHANGE-ME <<<

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

  # CHANGE-ME: pick your own hostname
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # CHANGE-ME: set to your own timezone, e.g. "America/New_York"
  time.timeZone = "UTC";

  # Port used by LocalSend (file sharing app). Remove if unused.
  networking.firewall.allowedTCPPorts = [ 53317 ];
  networking.firewall.allowedUDPPorts = [ 53317 ];

  services.desktopManager.plasma6.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.journald.extraConfig = "SystemMaxUse=200M";

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
  # lz4 chosen over zstd: cheaper to (de)compress, better fit for a
  # low-core-count CPU with no Turbo Boost headroom to spare.
  zramSwap = {
    enable = true;
    memoryPercent = 60;
    algorithm = "lz4";
  };

  services.flatpak.enable = true;
  services.thermald.enable = true;

  # NOTE on Baloo (KDE's file indexer): there's no NixOS module option
  # to disable it system-wide — it's a per-user Plasma setting. Disable
  # it with `balooctl6 disable` (or via System Settings > Search >
  # File Search) after rebuilding. It's a known background RAM/CPU
  # hog and worth turning off on lower-end hardware.

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

  # CHANGE-ME: replace with your own username
  users.users."CHANGE-ME" = {
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
    enableRenice = true;
    settings = {
      general = {
        # Prevents GameMode from fighting power-profiles-daemon over
        # governor control.
        desiredgov = "none";
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_vendor = "amd";
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
      vulkan-loader
      vulkan-validation-layers
    ];
    extraPackages32 = with pkgs.pkgsi686Linux; [
      mesa
      vulkan-loader
    ];
  };

  hardware.cpu.intel.updateMicrocode = true;
  hardware.amdgpu.initrd.enable = true;
  hardware.enableRedistributableFirmware = true;

  # Hybrid graphics note: if you have both an Intel iGPU and AMD dGPU,
  # Mesa RADV (default here, not AMDVLK) is the lighter/recommended driver.
  # To keep idle/desktop work on the lighter iGPU and reserve the dGPU
  # for demanding games, launch with:
  #   DRI_PRIME=1 %command%
  # as a per-game Steam launch option, or `DRI_PRIME=1 <app>` from a terminal.
  # Conversely, for lightweight 2D games, DRI_PRIME=0 keeps the dGPU
  # asleep entirely.

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
      pkgs.kdePackages.xdg-desktop-portal-kde
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
  boot.tmp.cleanOnBoot = true;

  # High swappiness is intentional here: swap is zram (RAM-backed, compressed),
  # not disk, so aggressive swapping doesn't cause the usual disk-thrashing
  # slowdown. This is a common tuning choice for 8GB systems.
  #
  # vfs_cache_pressure lowered from default (100) to keep filesystem
  # metadata caches around longer, reducing repeat disk I/O for apps/games
  # that touch many small files (e.g. mod assets).
  boot.kernel.sysctl = {
    "vm.swappiness" = 60;
    "vm.vfs_cache_pressure" = 50;
  };

  # CHANGE-ME: stateVersion should match the NixOS release you FIRST
  # installed with — do not bump this when you upgrade channels.
  system.stateVersion = "26.05";
}
