# GPU Mode Switching Guide - ROG Strix

Your system now has **3 GPU modes** with **automatic configuration**!

## 🎮 The Three Modes

### 1. **Dedicated Mode** (Current)
- **What:** NVIDIA RTX 4080 only
- **Performance:** ⚡ Maximum (direct display output)
- **Battery:** 🔋 Poor (RTX 4080 always active)
- **Best for:** Gaming, 4K 120Hz, maximum performance
- **BIOS MUX:** dGPU Mode

### 2. **Hybrid Mode** (Reverse Sync)
- **What:** NVIDIA renders, Intel outputs
- **Performance:** ⚡⚡ Good (better than Windows hybrid!)
- **Battery:** 🔋🔋 Okay (both GPUs active but can throttle)
- **Best for:** Balanced performance, high refresh displays
- **BIOS MUX:** Hybrid Mode

### 3. **Integrated Mode**
- **What:** Intel iGPU only
- **Performance:** ⚡ Basic (Intel integrated graphics)
- **Battery:** 🔋🔋🔋 Excellent (NVIDIA completely off)
- **Best for:** Web browsing, documents, maximum battery life
- **BIOS MUX:** Hybrid Mode (iGPU must be available)

---

## 🚀 Quick Switch (Easy Method)

### Option 1: Use the Script

```bash
cd /etc/nixos

# See current mode and options
./switch-gpu-mode.sh

# Switch to a specific mode
./switch-gpu-mode.sh dedicated
./switch-gpu-mode.sh hybrid
./switch-gpu-mode.sh integrated

# Then rebuild and reboot
sudo nixos-rebuild switch --flake '.#rog-strix'
sudo reboot
```

### Option 2: Edit Directly

Edit `/etc/nixos/hosts/rog-strix/gpu-mode.nix`:

```nix
myConfig.hardware.nvidia.mode = "dedicated";  # Change to: dedicated, hybrid, or integrated
```

Then rebuild and reboot:
```bash
sudo nixos-rebuild switch --flake '.#rog-strix'
sudo reboot
```

---

## 📋 Complete Switching Process

### Switching to Dedicated Mode

1. **Switch BIOS MUX** to **dGPU Mode**
   - Reboot → F2 → Advanced → Graphics → GPU Switch → dGPU
   - OR: Armoury Crate → System → Operating Mode → dGPU

2. **Update NixOS config:**
   ```bash
   cd /etc/nixos
   ./switch-gpu-mode.sh dedicated
   ```

3. **Rebuild and reboot:**
   ```bash
   sudo nixos-rebuild switch --flake '.#rog-strix'
   sudo reboot
   ```

4. **Verify:**
   ```bash
   lspci | grep -E 'VGA|3D'
   # Should show only NVIDIA GPU
   ```

### Switching to Hybrid Mode

1. **Switch BIOS MUX** to **Hybrid Mode**
   - Reboot → F2 → Advanced → Graphics → GPU Switch → Hybrid

2. **Update NixOS config:**
   ```bash
   cd /etc/nixos
   ./switch-gpu-mode.sh hybrid
   ```

3. **Rebuild and reboot:**
   ```bash
   sudo nixos-rebuild switch --flake '.#rog-strix'
   sudo reboot
   ```

4. **Verify:**
   ```bash
   lspci | grep -E 'VGA|3D'
   # Should show both Intel and NVIDIA GPUs
   
   # Check that reverse sync is active
   nvidia-smi
   # NVIDIA should show processes even on desktop
   ```

### Switching to Integrated Mode

1. **Switch BIOS MUX** to **Hybrid Mode**
   - (Same as hybrid - iGPU must be available)

2. **Update NixOS config:**
   ```bash
   cd /etc/nixos
   ./switch-gpu-mode.sh integrated
   ```

3. **Rebuild and reboot:**
   ```bash
   sudo nixos-rebuild switch --flake '.#rog-strix'
   sudo reboot
   ```

4. **Verify:**
   ```bash
   lspci | grep -E 'VGA|3D'
   # Should show both GPUs but NVIDIA will be powered off
   
   # Check NVIDIA is not loaded
   lsmod | grep nvidia
   # Should show nothing or minimal modules
   ```

---

## 🔧 What Happens Automatically

When you change the mode in `gpu-mode.nix`, the system automatically configures:

### Dedicated Mode
- ✅ Blacklists Intel GPU drivers (i915, xe)
- ✅ Disables Intel GPU in kernel params
- ✅ Loads NVIDIA drivers early (KMS)
- ✅ No PRIME configuration
- ✅ NVIDIA-specific X11 optimizations
- ✅ Direct display output from NVIDIA

### Hybrid Mode
- ✅ Enables both Intel and NVIDIA drivers
- ✅ Configures PRIME reverse sync
- ✅ Loads both GPU drivers early (KMS)
- ✅ NVIDIA always renders, Intel outputs
- ✅ Better performance than PRIME offload
- ✅ Smoother than Windows hybrid at high refresh!

### Integrated Mode
- ✅ Blacklists NVIDIA drivers
- ✅ Only loads Intel GPU driver
- ✅ NVIDIA completely powered off
- ✅ Maximum battery savings
- ✅ Intel handles all graphics

---

## 📊 Performance Comparison

| Scenario | Dedicated | Hybrid | Integrated |
|----------|-----------|--------|------------|
| 4K 120Hz Gaming | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ❌ |
| 1080p Gaming | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ❌ |
| Desktop (4K 120Hz) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Web Browsing | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Battery Life | ⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Input Latency | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 🎯 Recommended Usage

### Gaming Session (Plugged In)
```bash
./switch-gpu-mode.sh dedicated
```
- Maximum performance
- Lowest latency
- Best for competitive gaming

### Work/Development (Plugged In)
```bash
./switch-gpu-mode.sh hybrid
```
- Good performance
- Can use NVIDIA for CUDA/ML work
- Smooth desktop experience

### Mobile Use (On Battery)
```bash
./switch-gpu-mode.sh integrated
```
- Maximum battery life
- Perfect for web, documents, coding
- 4-6 hours battery life

---

## ❓ FAQ

### Q: Why is hybrid mode smoother than Windows now?
**A:** We're using PRIME reverse sync instead of offload. The NVIDIA GPU always renders (like dedicated mode), but outputs through Intel. This eliminates the switching lag you had before.

### Q: Can I switch modes without rebooting?
**A:** No, you must reboot after changing modes. The kernel modules and display drivers need to be reloaded.

### Q: Do I need to change BIOS MUX every time?
**A:** Only when switching between dedicated ↔ hybrid/integrated. You don't need to change BIOS when switching between hybrid ↔ integrated.

### Q: What if I forget to switch BIOS MUX?
**A:** The system won't boot properly or will show a black screen. Just reboot, switch the MUX in BIOS, and try again.

### Q: Which mode should I use by default?
**A:** 
- **Desktop replacement:** Dedicated (always plugged in)
- **Laptop use:** Hybrid (balanced)
- **Travel:** Integrated (maximum battery)

---

## 🐛 Troubleshooting

### Black screen after switching
1. Reboot to BIOS
2. Verify MUX switch matches your NixOS mode
3. Reboot again

### "No NVIDIA GPU found" in hybrid mode
- Check BIOS MUX is in Hybrid mode (not dGPU mode)
- Verify with: `lspci | grep -E 'VGA|3D'`

### Poor performance in hybrid mode
- This is expected with PRIME offload
- You're using reverse sync which should be smooth
- If still laggy, switch to dedicated mode

### Battery drains fast in integrated mode
- Check NVIDIA is actually off: `lsmod | grep nvidia` (should be empty)
- Check power usage: `sudo powertop`

---

## 📁 Files Modified by Mode System

All these files automatically configure based on your mode:

- `hosts/rog-strix/gpu-mode.nix` - Mode selector (YOU EDIT THIS)
- `modules/nixos/hardware/nvidia.nix` - NVIDIA driver, PRIME, env vars (automatic)
- `modules/nixos/system/boot-laptop.nix` - Kernel modules, blacklists, boot params (automatic)

You only need to edit `gpu-mode.nix` - everything else updates automatically!

---

## 🎉 Summary

You now have a **professional-grade GPU switching system** that:
- ✅ Supports 3 modes with one-line changes
- ✅ Automatically configures all settings
- ✅ Includes a convenient switching script
- ✅ Uses optimal configuration for each mode
- ✅ Hybrid mode is smoother than Windows!

**Current mode:** Dedicated (dGPU only)

Enjoy your perfectly configured ROG Strix! 🚀



