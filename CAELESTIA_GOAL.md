# Caelestia Hyprland Goal

Implement a declarative Caelestia-based Hyprland setup in `/etc/nixos` for host `pc-02`.

## Context

- Repo: `/etc/nixos`
- Host: `pc-02`
- Source of truth: NixOS flake and Home Manager config in this repo
- Do not run Caelestia's mutable installer.
- Do not edit generated `~/.config` files directly.
- Do not commit or push.
- Preserve unrelated dirty worktree changes.
- After Nix changes, run `nix fmt .`.
- Before claiming success, run `nixos-rebuild dry-build --flake .#pc-02`.
- If doing a live apply, run `sudo nixos-rebuild switch --flake /etc/nixos#pc-02`.

## Primary Objective

Replace the current Waybar/Fuzzel/SwayNC/wallust-driven Hyprland shell with a declarative Caelestia setup using:

- `https://github.com/caelestia-dots/shell`
- `https://github.com/caelestia-dots/caelestia`

Use upstream Caelestia defaults where safe, but keep the setup declarative and Nix-managed.

## Hard Gaming Invariant

Preserve the current gaming behavior even if upstream Caelestia differs:

- Keep Hyprland VRR enabled, equivalent to `misc:vrr = 3`.
- Keep tearing allowed, equivalent to `general:allow_tearing = true`.
- Keep immediate rules for games.
- Keep fullscreen/sync/fullscreen game handling for `steam_app_*` and `gamescope`.
- Keep idle inhibit for games where applicable.

This gaming VRR/immediate setup is the only non-negotiable behavior.

## Implementation Requirements

1. Add Caelestia Shell as a pinned stable flake input.
   - Use its Home Manager module.
   - Enable `programs.caelestia` declaratively.
   - Use the `with-cli` package if available.
   - Start it through the Home Manager systemd user service on `graphical-session.target`.
   - Do not also start it from Hyprland `exec-once`.

2. Add the broader Caelestia dots repo declaratively.
   - Do not run `install.fish`.
   - Do not symlink unmanaged mutable files from a home-directory clone.
   - Prefer a pinned Nix fetch or flake-style source reference.
   - Use upstream files as source material, then layer local overrides through Home Manager/Nix.

3. Replace Waybar fully.
   - Remove Waybar from the Hyprland home package set.
   - Remove Waybar autostart.
   - Remove the `hypr-shell-start` Waybar restart helper.
   - Remove Waybar layer rules.
   - Delete or stop importing the old `waybar.nix` module.
   - Remove Waybar CSS generation from theme scripts.

4. Switch Hyprland config toward Caelestia-style `.conf`.
   - The current setup generates `hypr/hyprland.lua`; replace that path with declarative `.conf` files.
   - Preserve the `pc-02` monitor config: `HDMI-A-1,3840x2160@119.88,0x0,1`.
   - Source local override files after upstream config for `pc-02` specifics and gaming invariants.

5. Let Caelestia own shell behavior.
   - Caelestia replaces Waybar as the shell.
   - Caelestia owns launcher, notifications/sidebar, session menu, lock action/UI, wallpaper, shell theming, media keys, brightness keys, and OSD.
   - `Super+Space` opens the Caelestia launcher.
   - `Super+N` opens the Caelestia sidebar/notification surface.
   - `Super+Shift+Q` opens the Caelestia session menu instead of directly exiting Hyprland.

6. Keep useful local workflows where they do not conflict.
   - Keep `cliphist`.
   - Keep `Super+V` clipboard picker, using Fuzzel as a dmenu helper if needed.
   - Keep and update `hypr-shortcuts` so it no longer mentions Waybar/SwayNC and uses Caelestia actions.
   - Keep Chrome as default browser.
   - Keep Dolphin as default file manager.
   - Install/configure Thunar if feasible, but Dolphin remains default.
   - Install/configure Foot and make Foot the Caelestia default terminal.
   - Keep Kitty available with static config, but remove wallust-driven dynamic Kitty recoloring.
   - Keep zsh as the login/default shell.
   - Fish may be configured from Caelestia dots if cleanly feasible, but do not make it the default shell.

7. Remove old theme ownership.
   - Caelestia owns wallpaper and shell color scheme.
   - Use `~/Pictures/Wallpapers` as the Caelestia wallpaper directory.
   - Remove the old wallust/awww dynamic theme pipeline where it only existed to recolor Waybar/Fuzzel/SwayNC/Hyprlock.
   - Keep only small static app config that is still useful.

8. Keep services safe.
   - Do not blindly enable all upstream Caelestia `exec-once` services.
   - Keep existing KWallet/polkit behavior unless a clear replacement is needed.
   - Prefer existing `hyprpolkitagent` over adding `polkit-gnome`.
   - Avoid adding geoclue/gammastep/trash cleanup unless explicitly required.
   - Keep clipboard watchers, MPRIS/resizer/cursor pieces only where needed.

9. Add external monitor brightness support.
   - Add NixOS i2c/DDC support so Caelestia brightness controls have a chance to work on the HDMI monitor.
   - Do this declaratively and minimally.

## Validation

- Run `nix fmt .`.
- Run `nixos-rebuild dry-build --flake .#pc-02`.
- If doing a live switch, run `sudo nixos-rebuild switch --flake /etc/nixos#pc-02`.
- After a fresh Hyprland session, verify:
  - `systemctl --user status caelestia`
  - `pgrep -af 'caelestia|quickshell'`
  - `pgrep -af waybar` shows no active Waybar
  - `hyprctl configerrors` has no errors
  - `hyprctl getoption general:allow_tearing` confirms tearing remains enabled
  - `hyprctl getoption misc:vrr` confirms VRR remains enabled
  - game windows such as `steam_app_*` and `gamescope` still receive immediate/fullscreen/idle-inhibit behavior

## Deliverable

A clean declarative `/etc/nixos` implementation of Caelestia for Hyprland on `pc-02`, with Waybar removed, Caelestia integrated through Home Manager/systemd, upstream Caelestia defaults used where safe, and the gaming VRR/immediate setup preserved.
