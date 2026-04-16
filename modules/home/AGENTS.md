# Home Manager subtree guidance

This directory is organized for **discoverability first**.

## Layout

- `base/` → shared user defaults like shell, git, ssh, tmux, gpg
- `desktop/` → UI-facing configuration such as Plasma, Konsole, MangoHud
- `features/` → optional or tool-specific integrations like opencode, factory, whisper-ptt, cliproxyapi
- `packages/` → package bundles only

## Preferred style in this repo

- Home Manager modules here do **not** all need custom options.
- Plain imported fragments are fine for shared defaults.
- Add option-gating only when the feature is truly optional per user/host.
- Keep `home/{jens,...}.nix` mostly as composition files:
  - imports
  - user identity
  - host/user-specific overrides

## Editing rules

- Before adding a new file, decide the domain first: `base`, `desktop`, `features`, or `packages`.
- Prefer moving complexity downward into focused modules rather than growing `home/*.nix`.
- When moving files, double-check relative paths to:
  - `../claude-skills`
  - `../../assets`
  - `../../secrets`
  - any `home.file.source` / `xdg.configFile.source`

## Validation

- Run `nix fmt`
- Run `nixos-rebuild dry-build --flake /etc/nixos#<affected-host>`
- For Home Manager changes used by Jens, `rog-strix` is the primary validation host
