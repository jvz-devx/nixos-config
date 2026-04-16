# Plasma subtree guidance

This subtree exists so KDE / plasma-manager config is easy to **find**, **edit**, and **extend** without turning back into one giant Plasma file.

## Core rule

When adding or changing Plasma settings, put them in the file that matches the concept, not in a catch-all file.

The goal here is not abstract purity — it is fast lookup when someone forgets where a Plasma setting belongs.

## Current file map

- `default.nix` → import hub only; keep this tiny
- `appearance.nix` → `programs.plasma.workspace` visuals, theme, cursor, icon theme, wallpaper, appearance-oriented `configFile` keys
- `fonts.nix` → `programs.plasma.fonts`, font aliases, font helper scripts, font-related hotkeys
- `panels.nix` → `programs.plasma.panels`, widgets, trays, launchers, host-specific dock contents
- `shortcuts.nix` → `programs.plasma.shortcuts` and general app-launch hotkeys
- `workspace.nix` → session/workspace behavior such as `powerdevil`, `kscreenlocker`, suspend/lock behavior
- `kwin.nix` → `programs.plasma.kwin`, KWin tuning, windowing behavior, Dolphin/KDE low-level config, `dataFile`/`configFile` tweaks related to the shell/window manager
- `packages.nix` → Plasma-supporting packages, Qt/Kvantum wiring, theming packages required by the desktop config

## Placement rules

### Put settings by concept, not by API surface

Do **not** group settings only because they all happen to use the same plasma-manager field.

For example:
- a `configFile` tweak for theme/appearance belongs in `appearance.nix`
- a `configFile` tweak for KWin/compositing belongs in `kwin.nix`
- a `configFile` tweak for session/lock/power belongs in `workspace.nix`

The conceptual home matters more than the raw attribute name.

### Quick decision guide

- visual appearance? → `appearance.nix`
- fonts or font helper logic? → `fonts.nix`
- panel/widget/tray/dock layout? → `panels.nix`
- keybindings or launcher commands? → `shortcuts.nix`
- suspend/lock/session/workspace behavior? → `workspace.nix`
- KWin, compositing, window rules, Dolphin or shell integration tweaks? → `kwin.nix`
- packages, Qt theme plumbing, Kvantum assets? → `packages.nix`

## Research-first workflow for Plasma edits

Before editing, first inspect the existing subtree instead of guessing:

1. check `default.nix` to see what files already exist
2. grep this directory for the Plasma option family you want:
   - `programs.plasma.workspace`
   - `programs.plasma.fonts`
   - `programs.plasma.panels`
   - `programs.plasma.shortcuts`
   - `programs.plasma.hotkeys.commands`
   - `programs.plasma.kwin`
   - `programs.plasma.configFile`
   - `programs.plasma.dataFile`
3. if the setting already fits a topic file, extend that file
4. only add a new file if the concept is genuinely distinct and the current file is getting crowded

## Patterns already used here

- **Host-specific panel launchers** live in `panels.nix` and branch on `osConfig.networking.hostName`
- **GPU-mode-dependent wallpaper** lives in `appearance.nix` and branches on `osConfig.myConfig.hardware.nvidia.mode`
- **Font helper scripts** live with the font config in `fonts.nix`
- **Low-level KDE config keys** are split by meaning between `appearance.nix`, `workspace.nix`, and `kwin.nix`

Follow those patterns instead of introducing a new style nearby.

## When to create a new Plasma file

Only split further when one of these is true:

- a file is becoming hard to scan
- the settings form a clear conceptual cluster
- future edits are likely to target that area repeatedly

Good future candidates might be:
- `notifications.nix`
- `dolphin.nix`
- `power.nix`

But only add them if the current files become unwieldy.

## Things to avoid

- Do not dump unrelated settings into `default.nix`
- Do not rebuild a giant `plasma.nix`
- Do not place settings only based on “it uses `configFile`”
- Do not introduce option-gating here unless there is a real user/host toggle requirement

## Relative path gotchas in this subtree

This directory is nested more deeply than most HM modules. Be careful with paths to:

- `../../../../assets/...`
- `../../../...` style references after moves
- any `xdg.configFile.source` or `home.file.source`

If moving a file, re-check all relative references manually.

## Validation

- Run `nix fmt`
- Run `nixos-rebuild dry-build --flake /etc/nixos#rog-strix`
- If you added new files under this subtree, make sure they are visible to the flake source during validation
