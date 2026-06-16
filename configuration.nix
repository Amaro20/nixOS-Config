{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "amaroNix";
  networking.networkmanager.enable = true;

  time.timeZone = ""; #timeZone here

  services.desktopManager.plasma6.enable = true;
  services.power-profiles-daemon.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "breeze";
    settings = {
      Theme = {
        # Replace the path below with the absolute path to your wallpaper image
        Background = "";
      };
    };
  };

  zramSwap = {
   enable = true;
   memoryPercent = 50;
  };

  services.flatpak.enable = true;
  services.thermald.enable = true;
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

  users.users.amaro = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "render"];
  };

  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.steam.gamescopeSession.enable = true;

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

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

  # Loads AMD drivers at earliest boot phase
  hardware.amdgpu.initrd.enable = true;

  hardware.enableRedistributableFirmware = true;

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

  qt.enable = true;
  qt.platformTheme = "kde";

 environment.etc."xdg/kitty/kitty.conf".text = ''
  # Correct Plasma 6 Kitty syntax
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
  boot.kernel.sysctl = { "vm.swappiness" = 100; };

  system.stateVersion = "26.05";
}
