# 🤖 Agent Intelligence & Guidelines

Welcome, fellow agent. This repository is a NixOS Flake-based configuration. Below is everything you need to know to navigate and contribute effectively.

## 🗺️ Repository Map

- **`flake.nix`**: The heart of the configuration. Defines all inputs and host outputs.
- **`hosts/`**: Host-specific configurations.
  - `configuration.nix`: The main entry point for a host.
  - `hardware-configuration.nix`: Hardware-specific auto-generated settings.
- **`modules/nixos/`**: System-level modules.
  - `profiles/`: High-level bundles (e.g., `gaming.nix`, `development.nix`).
  - `services/`, `hardware/`, `system/`: Atomic feature modules.
- **`home/`**: Home Manager configurations for users (Jens, Lisa, Admin).
- **`modules/home/`**: User-level modules and program configurations.
- **`pkgs/`**: Custom Nix packages not found in upstream nixpkgs.
- **`overlays/`**: Modifications to existing upstream packages.
- **`secrets/`**: Encrypted secrets managed by `sops-nix`.

## 📜 Coding Rules

1. **NO GIT PUSH/COMMIT**: You may `git add` files, but never `git commit` or `git push`.
2. **Formatting**: Always use `nix fmt` (uses `alejandra`) before finishing your task to ensure clean Nix code.
3. **Modularization**: Avoid putting everything in `configuration.nix`. If it's a reusable feature, create a module in `modules/nixos/` and import it.
4. **Declarative First**: Prefer declarative configurations (especially for KDE via `plasma-manager`) over imperative scripts.
5. **No Secrets in Plaintext**: Never put passwords or keys in `.nix` files. Use the `sops-nix` infrastructure.

## 🛠️ Common Operations

- **Search for options**: Use `man configuration.nix` or search [search.nixos.org](https://search.nixos.org/options).
- **Find defined modules**: Check `modules/nixos/default.nix` to see which modules are available.
- **Check Home Manager options**: See `home-manager` documentation or search online.
- **Test builds**: Use `nixos-rebuild build --flake .#<hostname>` to verify your changes without applying them.

## 🧠 Contextual Awareness

- This system uses **CachyOS kernel** for gaming hosts.
- **NVIDIA** is used on both `pc-02` and `rog-strix`.
- **KDE Plasma 6** is the primary desktop environment.
- **Tailscale** is used for networking between hosts.

Stay efficient. Stay declarative.