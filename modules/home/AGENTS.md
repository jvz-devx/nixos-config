# Home Manager subtree guidance

This directory is organized for the active macOS Home Manager profile first.

## Layout

- `base/` -> shared user defaults like git, ssh, tmux, and gpg
- `features/` -> macOS/work integrations such as encrypted Gooskens network drives
- `packages/` -> package bundles only
- `codex-skills/` and `claude-skills/` -> local agent skill files managed through Home Manager

## Preferred style in this repo

- Home Manager modules here do **not** all need custom options.
- Plain imported fragments are fine for shared defaults.
- Add option-gating only when the feature is truly optional per user/host.
- Keep `home/jens-darwin.nix` mostly as a composition file:
  - imports
  - user identity
  - host/user-specific overrides

## Editing rules

- Before adding a new file, decide the domain first: `base`, `features`, `packages`, or an agent-skill directory.
- Prefer moving complexity downward into focused modules rather than growing `home/*.nix`.
- When moving files, double-check relative paths to:
  - `../claude-skills`
  - `../codex-skills`
  - `../../../secrets`
  - any `home.file.source` / `xdg.configFile.source`

## Validation

- Run `nix fmt .` from the repository root.
- Run `nix build .#darwinConfigurations.macbook-pro.system` from the repository root.
- Run `sudo darwin-rebuild switch --flake .#macbook-pro` only when the user asks to apply the change.
