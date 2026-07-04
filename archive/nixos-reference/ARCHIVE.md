# NixOS Reference Archive

This directory contains the old Linux/NixOS setup removed from the active macOS flake.

Keep:

- `home/jens.nix` and `home/server.nix` for old Git and SSH identity hints.
- `hosts/*/hardware-configuration.nix` with each matching host.
- `modules/nixos/services/{sops,ssh,tailscale,nas,krdp}.nix` as useful service references.
- `modules/nixos/profiles/` for old desktop/server role composition.
- `modules/home/desktop/`, `modules/home/packages/gui/`, and archived Linux feature modules for Plasma, Hyprland, Stremio, Factory, opencode, and whisper workflows.
- `secrets/common.yaml` in the repository root; macOS still uses it and it also contains useful old encrypted material.

Drop later if unwanted:

- GPU tuning files: `GPU_MODE_GUIDE.md`, `switch-gpu-mode.sh`, `benchmark-30s.sh`, `framepacing-20260418-132716.log`.
- Desktop experiments: `CAELESTIA_GOAL.md`, `plasma-config.nix`.
- Linux installer helpers: `install.sh`, `create_server_iso.sh`.
