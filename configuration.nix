{ config, lib, pkgs, ... }:

let
  sddmTheme = pkgs.stdenv.mkDerivation {
    name = "sddm-breeze-custom";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/breeze-custom
      cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/. \
        $out/share/sddm/themes/breeze-custom/
      cp ${./assets/background.png} \
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
  networking.hostName = "nixos-host";
  networking.networkmanager.enable = true;
  time.timeZone = "UTC";

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

  users.users.username = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "render"
    ];
  };

  programs.firefox.enable = true;
  programs.steam.enable = true;
  programs.gamemode = {
    enable = true;
    enableRenice = true; 
  };
}
