---
name: hyprland-gaming
description: Hyprland/Steam gaming launch-option workflow for this NixOS machine. Use whenever the user asks for best settings for a game, Steam/Proton launch options, gamescope, MangoHud/MangoApp, VRR/adaptive sync, fullscreen game focus/hover/cursor issues, Rocket League-like settings, or says to optimize a game such as Black Ops 3 on Hyprland.
---

# Hyprland Gaming Profile

Use this for per-game Steam settings on Jens' NixOS Hyprland session. The known-good pattern is nested `gamescope` with VRR/adaptive sync, MangoHud kept out of the Vulkan layer, and gamescope's `--mangoapp` used for the overlay.

## Known-good profile

Generic Steam launch option for fullscreen Proton games:

```bash
env -u SDL_VIDEODRIVER MANGOHUD=0 LD_PRELOAD= ENABLE_VK_LAYER_VALVE_steam_overlay_1=0 DISABLE_VK_LAYER_VALVE_steam_overlay_1=1 gamescope --mangoapp -W 3840 -H 2160 -w 3840 -h 2160 -r 120 --adaptive-sync -f -b -g --force-grab-cursor -- env -u SDL_VIDEODRIVER MANGOHUD=0 %command%
```

For Rocket League specifically, keep the extra game flags after `%command%`:

```bash
+fps_max 117 +engine_low_latency_sleep_after_client_tick true
```

## Rules

- Keep `MANGOHUD=0` around both `gamescope` and the game. Do not restore global Steam `MANGOHUD=1`.
- Use `gamescope --mangoapp` for the overlay instead of regular MangoHud injection.
- Keep `LD_PRELOAD=` around `gamescope`; Steam overlay preloads can cause gamescope stutter.
- Keep Hyprland VRR enabled for the experiment: `misc:vrr = 3`.
- Keep `general:allow_tearing = true` and immediate game window rules if already present.
- Treat `--adaptive-sync` as useful but experimental on NVIDIA/Hyprland/gamescope.
- If mouse/cursor freezes return, first test removing `--force-grab-cursor`.
- If a launcher behaves badly, apply the profile only to the actual game executable or back out per-game.

## Workflow

1. Identify the Steam app ID and existing launch option. For Steam userdata on this machine, first check:

```bash
rg -n '"LaunchOptions"|"<appid>"|gamescope|mangoapp|MANGOHUD' /home/jens/.local/share/Steam/userdata/*/config/localconfig.vdf
```

2. Shut down Steam before editing `localconfig.vdf`; Steam can overwrite it while exiting. Verify no active game/gamescope process remains:

```bash
steam -shutdown || true
pgrep -af 'steam|steamwebhelper|RocketLeague|gamescope|steam_app_' || true
```

3. Back up `localconfig.vdf`, then edit only the relevant app's `LaunchOptions`.

4. For `.nix` changes under `/etc/nixos`, run:

```bash
nix fmt .
nixos-rebuild dry-build --flake .#pc-02
sudo nixos-rebuild switch --flake /etc/nixos#pc-02
```

5. Verify live Hyprland state:

```bash
hyprctl getoption misc:vrr
hyprctl getoption general:allow_tearing
hyprctl configerrors
```

6. After launching the game, verify the process command/environment if needed:

```bash
pgrep -af 'gamescope|steam_app_|RocketLeague|BlackOps|Call of Duty'
```

The expected shape is `gamescope --mangoapp ... --adaptive-sync ... -- env ... MANGOHUD=0 %command%`.

## Evidence

The prior local failure mode was repeated `gamescope-wl` crashes inside `libMangoHud.so`, causing desktop freezes while `systemd-coredump` processed dumps. Research found the same general guidance: traditional MangoHud injection with gamescope is unsupported; use `--mangoapp` instead.
