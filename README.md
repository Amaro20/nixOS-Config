# NixOS Config

Personal NixOS configuration — Plasma 6 desktop tuned for a
low-power, gaming-capable 8GB machine (Intel iGPU + AMD dGPU hybrid graphics).

## Important
-  Steam + Gamescope + GameMode, tuned for AMD RADV
-  zram swap + sysctl tuning for 8GB RAM
-  Custom SDDM theme, Starship prompt, Kitty terminal
-  Hybrid Intel/AMD graphics with per-app `DRI_PRIME` GPU offload

## Structure
- `configuration.nix` — main system config
- `hardware-configuration.nix` — machine-specific (not committed / gitignored)

```bash
sudo cp configuration.nix /etc/nixos/configuration.nix
sudo nixos-rebuild switch --upgrade
```

## Bash Configuration

```bash
# Initialize the Starship cross-shell prompt
eval "$(starship init bash)"

# Set the default backup prompt format
PS1='\u@\h:\w\$ '

# Run system information fetch tool on startup
fastfetch

## License
MIT License
