---
name: nix-writer
description: Write correct, modern, idiomatic Nix for this macOS nix-darwin flake: Darwin modules, Home Manager, nix-homebrew, flakes, and repo-local packages.
user-invocable: true
---

# Nix Writer

This repo is `/Users/jens/nix`: a macOS-first nix-darwin flake for `macbook-pro`.

## Local rules

1. Read `AGENTS.md`, `flake.nix`, and the nearest subtree `AGENTS.md` before editing.
2. Keep `darwinConfigurations.macbook-pro` as the active system target.
3. Keep `home/jens-darwin.nix` mostly as composition: imports, identity, session defaults, host/user overrides.
4. Put reusable macOS system behavior under `modules/darwin/`.
5. Put reusable Home Manager behavior under `modules/home/base/`, `modules/home/features/`, or `modules/home/packages/`.
6. Put persistent Homebrew packages in `modules/darwin/homebrew.nix`, not in manual Brew state.
7. Treat `archive/nixos-reference/` as reference-only unless Jens explicitly asks to restore or inspect it.

## Style

- Use SRI hashes: `hash = "sha256-..."`.
- Prefer `finalAttrs:` derivations where it stays readable.
- Prefer `lib.getExe` plus `meta.mainProgram` over hard-coded bin paths.
- Use `lib.mkIf` for conditional config.
- Avoid new abstractions unless they remove real duplication.
- Keep platform-specific package expressions honest with `meta.platforms`.

## Validation

For `.nix` edits:

```bash
nix fmt .
nix build .#darwinConfigurations.macbook-pro.system
```

For package-only edits, also build the package:

```bash
nix build .#<package-name>
```

Apply the machine config only when asked:

```bash
sudo darwin-rebuild switch --flake .#macbook-pro
```
