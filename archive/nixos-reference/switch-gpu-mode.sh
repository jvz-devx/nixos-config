#!/usr/bin/env bash
# GPU Mode Switcher for ROG Strix G16 (G614JZ)
# Switches GPU mode, rebuilds NixOS, and reboots — all in one command.
#
# Usage:
#   ./switch-gpu-mode.sh <mode>       Switch to a mode (dedicated/hybrid/integrated)
#   ./switch-gpu-mode.sh              Show current mode and available options
#   ./switch-gpu-mode.sh status       Show current mode
#
# ============================================================================
# MODES
# ============================================================================
#
#   dedicated    - dGPU only, max performance
#                  BIOS MUX: dGPU Mode (F2 -> Advanced -> Graphics -> dGPU)
#                  Battery: ~1.5h | Best for: gaming, 4K 120Hz
#
#   hybrid       - NVIDIA renders, Intel outputs (reverse PRIME sync)
#                  BIOS MUX: Hybrid Mode
#                  Battery: ~2h | Best for: balanced use, external displays
#
#   integrated   - iGPU only, best battery life
#                  BIOS MUX: Hybrid Mode
#                  Battery: ~3h | Best for: web browsing, documents, travel
#
# ============================================================================
# WHAT CHANGES PER MODE (automatic via NixOS modules)
# ============================================================================
#
# Integrated mode:
#   - NVIDIA/nouveau/xe kernel modules blacklisted (dGPU fully off, D3cold)
#   - Intel i915 drives display, intel-media-driver for VA-API
#   - power-profiles-daemon active (use Fn key to switch profiles)
#   - powertop auto-tune runs on boot
#   - Static wallpaper (video wallpaper disabled to save power)
#   - Set power profile to "power-saver" via Fn key for best battery
#
# Dedicated mode:
#   - Full NVIDIA proprietary driver loaded
#   - xe (Intel discrete GPU driver) blacklisted
#   - power-profiles-daemon active
#   - nvidia-vaapi-driver for VA-API
#   - Video wallpaper enabled
#
# Hybrid mode:
#   - NVIDIA PRIME reverse sync (NVIDIA renders, Intel outputs)
#   - power-profiles-daemon active
#   - nvidia-vaapi-driver for VA-API
#   - Video wallpaper enabled
#
# ============================================================================
# FILES MODIFIED BY THE MODE SYSTEM
# ============================================================================
#
#   hosts/rog-strix/gpu-mode.nix            - Mode selector (this script edits it)
#   modules/nixos/hardware/nvidia.nix       - NVIDIA driver, PRIME, VA-API, env vars
#   modules/nixos/system/boot-laptop.nix    - Kernel modules, blacklists, boot params
#   modules/nixos/system/power.nix          - powertop auto-tune
#   modules/nixos/hardware/asus.nix         - power-profiles-daemon, charge limit
#   modules/home/plasma.nix                 - Wallpaper (static vs video)
#
# ============================================================================
# BATTERY TIPS
# ============================================================================
#
#   - Use Fn key to set power profile to "power-saver" in integrated mode
#   - Lower screen brightness (biggest single impact, 3-5W difference)
#   - Battery charge limit is set to 80% to reduce wear (see asus.nix)
#   - Use "asusctl --one-shot-chg" for a one-time full charge before travel
#   - Battery health: check with "cat /sys/class/power_supply/BAT0/energy_full"
#     vs design capacity in energy_full_design (90Wh)
#
# ============================================================================
# POWER OPTIMIZATION NOTES (tested on this hardware)
# ============================================================================
#
#   What works:
#     - powertop --auto-tune (saves ~3W, runs via systemd on boot)
#     - power-profiles-daemon "power-saver" (saves ~8W vs performance)
#     - Blacklisting nvidia/nouveau/xe (dGPU enters D3cold, fully off)
#     - Static wallpaper instead of video wallpaper
#
#   What was tested and didn't help or made things worse:
#     - thermald: 4s polling interval prevents package C-states (all PC 0%)
#     - auto-cpufreq: conflicts with power-profiles-daemon, loses Fn key
#     - pcie_aspm=force/powersupersave: BIOS FADT disables ASPM, no effect
#     - i915.enable_psr=2: didn't improve C-states
#     - i915.enable_fbc=1: no measurable effect
#     - acpi.ec_no_wakeup=1: no effect on package C-states
#
#   Hardware limitations:
#     - BIOS FADT declares no PCIe ASPM support (can't be overridden)
#     - Package C-states rarely go above PC2 due to active PCI devices
#       (VMD RAID controller, USB, WiFi, NVMe all stay in D0)
#     - ~21-25W is the idle floor on Linux for this hardware
#     - Windows achieves ~15W via Intel DPTF + ASUS Armoury Crate tuning
#       that has no full Linux equivalent
#
# ============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GPU_MODE_FILE="$SCRIPT_DIR/hosts/rog-strix/gpu-mode.nix"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

die() { echo -e "${RED}Error:${NC} $1" >&2; exit 1; }

# Sanity checks
[[ -f "$GPU_MODE_FILE" ]] || die "gpu-mode.nix not found at $GPU_MODE_FILE"
[[ -f "$SCRIPT_DIR/flake.nix" ]] || die "Not in the NixOS flake directory"

get_current_mode() {
    grep 'myConfig.hardware.nvidia.mode = ' "$GPU_MODE_FILE" | sed 's/.*"\(.*\)".*/\1/'
}

print_header() {
    echo ""
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ${BOLD}ROG Strix GPU Mode Switcher${NC}"
    echo -e "${BLUE}══════════════════════════════════════════════════════════════${NC}"
}

print_current_mode() {
    local current_mode=$(get_current_mode)
    echo -e "  ${GREEN}Current mode:${NC} ${YELLOW}${BOLD}$current_mode${NC}"
    echo ""
}

print_modes() {
    echo "  Available modes:"
    echo ""
    echo -e "  ${GREEN}dedicated${NC}    dGPU only (max performance, poor battery)"
    echo -e "               BIOS MUX: ${YELLOW}dGPU Mode${NC}"
    echo ""
    echo -e "  ${GREEN}hybrid${NC}       Reverse sync (good performance, okay battery)"
    echo -e "               BIOS MUX: ${YELLOW}Hybrid Mode${NC}"
    echo ""
    echo -e "  ${GREEN}integrated${NC}   iGPU only (best battery, basic performance)"
    echo -e "               BIOS MUX: ${YELLOW}Hybrid Mode${NC}"
    echo ""
}

print_mode_details() {
    local mode=$1
    echo -e "  ${BOLD}What will change:${NC}"
    case $mode in
        integrated)
            echo "    - NVIDIA/nouveau/xe drivers blacklisted (dGPU fully off)"
            echo "    - Intel i915 + intel-media-driver for VA-API"
            echo "    - powertop auto-tune on boot"
            echo "    - Static wallpaper (video wallpaper disabled)"
            echo "    - Use Fn key to set power-saver profile for best battery"
            ;;
        dedicated)
            echo "    - Full NVIDIA driver loaded"
            echo "    - power-profiles-daemon for performance control"
            echo "    - NVIDIA VA-API for video acceleration"
            echo "    - Video wallpaper enabled"
            ;;
        hybrid)
            echo "    - NVIDIA PRIME reverse sync (NVIDIA renders, Intel outputs)"
            echo "    - power-profiles-daemon for performance control"
            echo "    - NVIDIA VA-API for video acceleration"
            echo "    - Video wallpaper enabled"
            ;;
    esac
    echo ""
}

switch_mode() {
    local new_mode=$1
    local current_mode=$(get_current_mode)

    if [[ "$current_mode" == "$new_mode" ]]; then
        echo -e "  ${YELLOW}Already in ${BOLD}$new_mode${NC}${YELLOW} mode. Nothing to do.${NC}"
        echo ""
        exit 0
    fi

    echo -e "  ${BOLD}Switching:${NC} ${YELLOW}$current_mode${NC} -> ${GREEN}${BOLD}$new_mode${NC}"
    echo ""
    print_mode_details "$new_mode"

    # BIOS MUX reminder
    case $new_mode in
        dedicated)
            if [[ "$current_mode" != "dedicated" ]]; then
                echo -e "  ${RED}${BOLD}IMPORTANT:${NC} You must change BIOS MUX to ${BOLD}dGPU Mode${NC}"
                echo -e "           (F2 on boot -> Advanced -> Graphics -> dGPU)"
                echo ""
            fi
            ;;
        hybrid|integrated)
            if [[ "$current_mode" == "dedicated" ]]; then
                echo -e "  ${RED}${BOLD}IMPORTANT:${NC} You must change BIOS MUX to ${BOLD}Hybrid Mode${NC}"
                echo -e "           (F2 on boot -> Advanced -> Graphics -> Hybrid)"
                echo ""
            fi
            ;;
    esac

    # Confirm
    read -p "  Proceed? [y/N] " -n 1 -r
    echo ""
    [[ $REPLY =~ ^[Yy]$ ]] || { echo "  Cancelled."; exit 0; }
    echo ""

    # Update config
    sed -i "s/myConfig.hardware.nvidia.mode = \".*\"/myConfig.hardware.nvidia.mode = \"$new_mode\"/" "$GPU_MODE_FILE"
    echo -e "  ${GREEN}✓${NC} Configuration updated"

    # Rebuild (exit code 4 = activation warnings like failed services, not a build failure)
    echo -e "  ${BLUE}Rebuilding NixOS...${NC}"
    echo ""
    local rc=0
    sudo nixos-rebuild switch --flake "$SCRIPT_DIR#rog-strix" || rc=$?
    if [[ $rc -eq 0 || $rc -eq 4 ]]; then
        echo ""
        echo -e "  ${GREEN}${BOLD}✓ Rebuild complete${NC}"
        [[ $rc -eq 4 ]] && echo -e "  ${YELLOW}(some services had warnings, this is normal)${NC}"
    else
        echo ""
        echo -e "  ${RED}${BOLD}✗ Rebuild failed!${NC} Reverting to $current_mode..."
        sed -i "s/myConfig.hardware.nvidia.mode = \".*\"/myConfig.hardware.nvidia.mode = \"$current_mode\"/" "$GPU_MODE_FILE"
        echo -e "  ${GREEN}✓${NC} Reverted to $current_mode"
        exit 1
    fi
    echo ""

    # Reboot
    echo -e "  ${YELLOW}Reboot required to apply changes.${NC}"
    read -p "  Reboot now? [Y/n] " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo -e "  ${BLUE}Rebooting...${NC}"
        sudo reboot
    else
        echo -e "  Run ${GREEN}sudo reboot${NC} when ready."
    fi
}

# Main
print_header

if [[ $# -eq 0 ]]; then
    print_current_mode
    print_modes
    echo -e "  Usage: ${GREEN}$0 <mode>${NC}"
    echo ""
    exit 0
fi

MODE=$1

case $MODE in
    dedicated|hybrid|integrated)
        print_current_mode
        switch_mode "$MODE"
        ;;
    status)
        print_current_mode
        ;;
    *)
        die "Invalid mode '$MODE'. Valid: dedicated, hybrid, integrated"
        ;;
esac
