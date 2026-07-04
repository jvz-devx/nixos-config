# AGENTS.md

This file provides guidance to coding agents working in this repository.

## Build & Test

```bash
# Format all Nix files before finishing changes
nix fmt .

# Build the macOS system configuration without switching
nix build .#darwinConfigurations.macbook-pro.system

# Apply macOS configuration changes
sudo darwin-rebuild switch --flake .#macbook-pro

# Update flake inputs
nix flake update

# Build a custom package
nix build .#<package-name>
```

## Validation Rule

After modifying any `.nix` file, run `nix fmt .` and `nix build .#darwinConfigurations.macbook-pro.system`. Fix build errors before considering the task complete.

Run `sudo darwin-rebuild switch --flake .#macbook-pro` only when the user asks to apply changes or when applying them is clearly part of the requested task.

## Architecture Overview

This repository is Jens's macOS nix-darwin flake for `macbook-pro`. It uses nixpkgs-unstable, nix-darwin, Home Manager, nix-homebrew, and sops-nix.

The active host is:

| Host | User | Platform | Profile |
|------|------|----------|---------|
| `macbook-pro` | jens | Apple Silicon macOS | workstation |

Archived Linux/NixOS reference material lives under `archive/nixos-reference/`. It is not part of the active flake; do not edit, validate, or reintroduce it unless the user explicitly asks.

## Conventions & Patterns

### Darwin Modules

macOS system configuration lives under `hosts/macbook-pro/` and `modules/darwin/`.

Use nix-darwin options for system defaults, launchd services, Homebrew integration, networking, fonts, and macOS-specific behavior.

### Home Manager

The active user configuration is `home/jens-darwin.nix`. Shared Home Manager fragments live in `modules/home/`.

Keep `home/jens-darwin.nix` mostly as a composition file:

- imports
- user identity and session defaults
- host/user-specific overrides

Put substantial behavior in focused modules under `modules/home/base/`, `modules/home/features/`, or `modules/home/packages/`.

### Homebrew

Manage persistent Homebrew packages declaratively in `modules/darwin/homebrew.nix`.

- Use `casks` for GUI apps and Mac-specific app bundles.
- Use `brews` for Mac-specific or ecosystem-sensitive CLI tools.
- If a Homebrew formula should start at login, declare it as an attribute set with `start_service = true`.

Do not leave manual `brew install`, `brew uninstall`, or `brew services` changes unmanaged when they should be persistent.

### Overlays

`overlays/default.nix` exposes overlays used by the flake:

- **additions**: custom packages from `pkgs/`
- **modifications**: patched upstream packages
- **stable-packages**: makes `pkgs.stable.*` available from nixpkgs-stable

### Custom Packages

`pkgs/` contains custom derivations. Build with `nix build .#<name>`.

## Security

Secrets are managed by sops-nix with age encryption. Encrypted files live in `secrets/`.

Never put secrets, private URLs, tokens, passwords, or credentials in plaintext `.nix` files. Use `sops secrets/<file>.yaml` or `sops set` with `--value-file`/`--value-stdin` to avoid leaking secret values into shell history or process arguments.

## Tools

Use fast search tools such as `rg` and `rg --files` for repository inspection.

## Git Workflows

- Inspect `git status --short --branch` and the relevant diff before staging, committing, or pushing.
- Do not commit or push unless the user explicitly asks for that git action.
- Stage only files that belong to the requested change. Do not silently include unrelated dirty work.
- Before pushing, state the branch, remote, commit message, and scope when the worktree contains mixed changes.
- Prefer pushing the current branch with tracking via `git push -u origin $(git branch --show-current)`.
- Never force-push, rewrite history, delete branches, or run destructive git commands unless the user explicitly asks for that exact operation.

## Repository Layout

- **`flake.nix`** defines inputs and the `macbook-pro` Darwin output.
- **`hosts/macbook-pro/`** contains host-specific macOS configuration.
- **`modules/darwin/`** contains reusable nix-darwin modules.
- **`home/jens-darwin.nix`** is Jens's active Home Manager entry point on macOS.
- **`modules/home/`** contains reusable Home Manager modules.
- **`pkgs/`** contains custom derivations.
- **`overlays/`** contains nixpkgs overlays.
- **`secrets/`** contains encrypted secret material.
- **`archive/nixos-reference/`** contains old Linux/NixOS material for reference only.
