# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Multi-host NixOS flake configuration managing desktops, a laptop, a server, and WSL. Uses nixpkgs-unstable, Home Manager, plasma-manager (KDE Plasma 6), sops-nix (secrets), and chaotic-nyx (CachyOS kernel).

## Hosts

| Host | User | Hardware | Profile |
|------|------|----------|---------|
| `rog-strix` | jens | Intel + NVIDIA laptop (ASUS) | workstation |
| `pc-02` | jens | AMD + NVIDIA desktop | workstation |
| `server-01` | admin | x86_64 headless (nixpkgs-stable) | server |
| `wsl` | jens | WSL2 | minimal |

## Commands

```bash
# Dry build (MUST run after any .nix change, before telling user you're done)
nixos-rebuild dry-build --flake ".#<hostname>"

# Apply changes
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Format all nix files (MUST run before finishing any task)
nix fmt

# Update flake inputs
nix flake update

# Build custom ISO
nix build .#<hostname>-iso

# Build a custom package
nix build .#<package-name>

# Switch GPU mode on rog-strix (dedicated/hybrid/integrated)
# This updates gpu-mode.nix, rebuilds, and prompts to reboot
./switch-gpu-mode.sh <mode>
```

## Validation Rule

After modifying any `.nix` file, you **must** run a dry build for the affected host(s) and fix any errors before considering the task complete. Multiple hosts may be affected — check which hosts use the changed module.

## Architecture

### Custom Option Namespace

All custom modules use the `myConfig.*` option namespace. Modules declare options with `lib.mkEnableOption` and gate their config behind `lib.mkIf`:

```
myConfig.profiles.{workstation,desktop,gaming,development,server}.enable
myConfig.hardware.{nvidia,cpu.amd,cpu.intel,audio,bluetooth,asus,logitech}.enable
myConfig.desktop.{plasma,portals}.enable
myConfig.programs.{gaming,localsend,development}.enable
myConfig.services.{tailscale,maintenance,sops,nas,flatpak}.enable
myConfig.system.{locale,boot,disk,power,iso}.enable
```

### Profile Hierarchy

Profiles are composable bundles in `modules/nixos/profiles/`. The hierarchy is:

- **workstation** = desktop + gaming + development (used by `rog-strix`, `pc-02`)
- **desktop** = plasma + portals + flatpak + audio + bluetooth + logitech + locale + boot + disk + maintenance
- **gaming** = Steam, Heroic, Lutris, MangoHud
- **development** = Docker, CLI tools, language environments
- **server** = locale + boot + disk + maintenance + tailscale + development (headless, no desktop)

Hosts enable a profile in their `configuration.nix`, then add host-specific overrides.

### Module Index

`modules/nixos/default.nix` imports **all** NixOS modules for every host. Modules are opt-in via their `enable` option — importing does not activate anything.

### Home Manager

User configs live in `home/{jens,server,wsl}.nix`. Each imports modules from `modules/home/` (shell, programs, plasma, packages). Home modules are **not** option-gated — they activate by being imported.

The `rebuild` shell alias is defined per-user and points to the correct `--flake .#<hostname>`.

### Overlays

`overlays/default.nix` exposes three overlays applied per-host:
- **additions**: custom packages from `pkgs/`
- **modifications**: patched upstream packages (Vesktop, Discord+Vencord, rust-overlay)
- **stable-packages**: makes `pkgs.stable.*` available from nixpkgs-stable

### Custom Packages

`pkgs/` contains custom derivations (coderabbit, sqlit-tui, smart-video-wallpaper). Build with `nix build .#<name>`.

### Secrets

Managed by sops-nix with age encryption. Encrypted files in `secrets/`. Edit with `sops secrets/<file>.yaml`. Never put secrets in plaintext `.nix` files.

## Tools

For any file search or grep in the current git indexed directory use fff tools.

## CLAUDE.md Terminology

- When the user refers to the "global `CLAUDE.md`", they mean the Home Manager source in `home/jens.nix` that generates `~/.claude/CLAUDE.md`, not the repo-local `/etc/nixos/CLAUDE.md`.

## Coding Rules

- **Format with `nix fmt`** (uses alejandra) before finishing.
- **Modularize**: new reusable features go in `modules/nixos/` or `modules/home/` with a `myConfig.*` enable option, then import in `modules/nixos/default.nix`.
- **Declarative first**: prefer declarative config (especially plasma-manager for KDE) over imperative scripts.
- **No git commit/push**: you may `git add` but never commit or push.
