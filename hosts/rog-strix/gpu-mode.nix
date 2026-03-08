# GPU Mode Selector for ROG Strix with MUX Switch
# ═══════════════════════════════════════════════════════════════════════
#
# This file controls GPU behavior across all configuration files.
# Change ONLY the 'mode' value below, then rebuild.
#
# IMPORTANT: After changing mode here, also switch the MUX in BIOS!
#
# ═══════════════════════════════════════════════════════════════════════
{lib, ...}: {
  # ┌─────────────────────────────────────────────────────────────────┐
  # │ SET YOUR GPU MODE HERE - Change this value to switch modes      │
  # └─────────────────────────────────────────────────────────────────┘

  # Set GPU mode using the new myConfig option
  myConfig.hardware.nvidia.mode = "dedicated";
}
# ═══════════════════════════════════════════════════════════════════════
# MODE DESCRIPTIONS
# ═══════════════════════════════════════════════════════════════════════
#
# 1. DEDICATED MODE (dGPU only)
#    ├─ BIOS MUX Switch: dGPU mode
#    ├─ Performance: Maximum (direct display output)
#    ├─ Battery: Poor (RTX 4080 always active)
#    ├─ Use case: Gaming, 4K 120Hz, maximum performance
#    └─ NVIDIA renders directly to display, no copy overhead
#
# 2. HYBRID MODE (Reverse Sync)
#    ├─ BIOS MUX Switch: Hybrid mode
#    ├─ Performance: Good (NVIDIA always rendering, Intel output)
#    ├─ Battery: Okay (both GPUs active but can throttle)
#    ├─ Use case: Balanced performance, high refresh displays
#    └─ NVIDIA renders everything, Intel handles display output
#
# 3. INTEGRATED MODE (iGPU only)
#    ├─ BIOS MUX Switch: Hybrid mode (iGPU must be available)
#    ├─ Performance: Basic (Intel integrated graphics only)
#    ├─ Battery: Excellent (NVIDIA completely off)
#    ├─ Use case: Web browsing, documents, maximum battery life
#    └─ NVIDIA is completely powered off, Intel handles everything
#
# ═══════════════════════════════════════════════════════════════════════
# HOW TO SWITCH MODES
# ═══════════════════════════════════════════════════════════════════════
#
# 1. Change the myConfig.hardware.nvidia.mode value above
# 2. Switch MUX in BIOS (if needed - see table below)
# 3. Rebuild: sudo nixos-rebuild switch --flake '.#rog-strix'
# 4. Reboot
#
# MUX Switch Requirements:
# ┌─────────────┬──────────────────┐
# │ NixOS Mode  │ BIOS MUX Setting │
# ├─────────────┼──────────────────┤
# │ dedicated   │ dGPU Mode        │
# │ hybrid      │ Hybrid Mode      │
# │ integrated  │ Hybrid Mode      │
# └─────────────┴──────────────────┘
#
# ═══════════════════════════════════════════════════════════════════════

