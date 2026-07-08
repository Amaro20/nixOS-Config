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

## Kitty Configuration

```conf
# -------------------------------
# Kitty Terminal Config
# -------------------------------

linux_display_server wayland

background_opacity 0.30
dynamic_background_opacity yes
background_blur 1
hide_window_decorations yes

background #0a192f
foreground #00BFFF

font_family Hack
bold_font auto
italic_font auto
bold_italic_font auto
font_size 12.0
enable_ligatures yes

window_padding_width 12
remember_window_size no
initial_window_width 1152
initial_window_height 600

repaint_delay 10
sync_to_monitor yes

scrollback_lines 10000

shell_integration no-cursor
cursor_shape block
cursor_blinking off
cursor_blink_interval 0
cursor_trail 1
cursor_trail_decay 0.1 0.4

## License
MIT License
