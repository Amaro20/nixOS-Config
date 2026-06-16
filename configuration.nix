{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Allow proprietary packages
  nixpkgs.config.allowUnfree = true;

  # Network
  networking.hostName = "amaroNix";
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "";

  # KDE Plasma + SDDM
  services.desktopManager.plasma6.enable = true;

  services.power-profiles-daemon.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;

    # Put your wallpaper here:
    # assets/wallpaper.png

    theme = "${pkgs.runCommand "breeze-sddm-custom" {} ''
      mkdir -p $out/share/sddm/themes/breeze

      cp -r ${pkgs.kdePackages.sddm-kcm}/share/sddm/themes/breeze/* \
        $out/share/sddm/themes/breeze/

      cat > $out/share/sddm/themes/breeze/theme.conf.user <<EOF
[General]
background=${./assets/wallpaper.png}
EOF
    ''}/share/sddm/themes/breeze";
  };

  # ZRAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Services
  services.flatpak.enable = true;
  services.thermald.enable = true;

  # Audio
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

  # User
  users.users.amaro = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
    ];
  };

  # Programs
  programs.firefox.enable = true;

  programs.steam.enable = true;
  programs.gamemode.enable = true;

  programs.steam.gamescopeSession.enable = true;

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;

    extraPackages = with pkgs; [
      mesa
      libva-vdpau-driver
      libvdpau-va-gl

      # Intel + AMD hybrid only:
      # intel-media-driver
      # intel-vaapi-driver
    ];
  };

  hardware.amdgpu.initrd.enable = true;

  hardware.enableRedistributableFirmware = true;

  # Packages
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

    vulkan-tools
    mangohud
    pavucontrol
    fastfetch

    prismlauncher
    discord
  ];

  # Qt
  qt.enable = true;
  qt.platformTheme = "kde";

  # Kitty config
  environment.etc."xdg/kitty/kitty.conf".text = ''
    cursor_shape block
    cursor_blink_interval 0
    cursor_trail 1
    cursor_trail_decay 0.1 0.4
  '';

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.device = "nodev";

  # Keep 2 generations
  boot.loader.grub.configurationLimit = 2;

  # RAM
  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
  };

  system.stateVersion = "26.05";
}
