#!/usr/bin/env bash
# NixOS First Install Script
# This script sets up a fresh NixOS installation from this flake
#
# Usage: ./install.sh <hostname>
# Example: ./install.sh pc-02

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Check if running as root or with sudo available
check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        if ! command -v sudo &> /dev/null; then
            error "This script must be run as root or with sudo available"
        fi
        SUDO="sudo"
    else
        SUDO=""
    fi
}

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Validate hostname argument
validate_hostname() {
    local hostname="$1"
    local valid_hosts=("pc-02" "rog-strix" "server-01")
    
    for host in "${valid_hosts[@]}"; do
        if [[ "$hostname" == "$host" ]]; then
            return 0
        fi
    done
    
    error "Invalid hostname '$hostname'. Valid options: ${valid_hosts[*]}"
}

# Disk installation mode
disk_install() {
    local hostname="$1"
    
    echo ""
    warn "!!! DISK INSTALLATION MODE !!!"
    warn "This will WIPE a disk and perform a fresh NixOS installation."
    echo ""
    
    # 1. List disks
    info "Available disks:"
    lsblk -dno NAME,SIZE,MODEL | grep -v "loop" | grep -v "zram"
    echo ""
    
    read -p "Enter the device name to wipe (e.g., sda, vda, nvme0n1): " DISK_NAME
    local DISK="/dev/$DISK_NAME"
    
    if [[ ! -b "$DISK" ]]; then
        error "Device $DISK not found or not a block device."
    fi
    
    warn "WARNING: Everything on $DISK will be DESTROYED."
    read -p "Are you absolutely sure? (type 'yes' to continue): " CONFIRM
    if [[ "$CONFIRM" != "yes" ]]; then
        error "Installation aborted."
    fi
    
    # 2. Partitioning
    info "Partitioning $DISK..."
    $SUDO parted "$DISK" -- mklabel gpt
    $SUDO parted "$DISK" -- mkpart ESP fat32 1MiB 512MiB
    $SUDO parted "$DISK" -- set 1 esp on
    $SUDO parted "$DISK" -- mkpart primary ext4 512MiB 100%
    
    # Handle NVMe naming convention (p1, p2) vs SCSI (1, 2)
    local PART_BOOT="${DISK}1"
    local PART_ROOT="${DISK}2"
    if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
        PART_BOOT="${DISK}p1"
        PART_ROOT="${DISK}p2"
    fi
    
    # 3. Formatting
    info "Formatting partitions (Btrfs)..."
    $SUDO mkfs.fat -F 32 "$PART_BOOT"
    $SUDO mkfs.btrfs -f "$PART_ROOT"
    
    # 4. Mounting and subvolumes
    info "Creating Btrfs subvolumes..."
    $SUDO mount "$PART_ROOT" /mnt
    $SUDO btrfs subvolume create /mnt/root
    $SUDO btrfs subvolume create /mnt/home
    $SUDO btrfs subvolume create /mnt/nix
    $SUDO btrfs subvolume create /mnt/log
    $SUDO umount /mnt
    
    info "Mounting subvolumes..."
    $SUDO mount -o compress=zstd,subvol=root "$PART_ROOT" /mnt
    $SUDO mkdir -p /mnt/{boot,home,nix,var/log}
    $SUDO mount -o compress=zstd,subvol=home "$PART_ROOT" /mnt/home
    $SUDO mount -o compress=zstd,subvol=nix "$PART_ROOT" /mnt/nix
    $SUDO mount -o compress=zstd,subvol=log "$PART_ROOT" /mnt/var/log
    $SUDO mount "$PART_BOOT" /mnt/boot
    
    # 5. Generate hardware config
    info "Generating hardware configuration for the new disk..."
    $SUDO nixos-generate-config --root /mnt --show-hardware-config > "$SCRIPT_DIR/hosts/$hostname/hardware-configuration.nix"
    
    # 6. Copy flake to the new system (to /mnt/etc/nixos)
    info "Copying flake to the new system..."
    $SUDO mkdir -p /mnt/etc/nixos
    $SUDO cp -r "$SCRIPT_DIR"/* /mnt/etc/nixos/
    
    # 7. Perform the installation
    info "Starting nixos-install..."
    if $SUDO nixos-install --flake "/mnt/etc/nixos#$hostname" --no-root-passwd; then
        success "NixOS successfully installed to $DISK!"
        echo ""
        info "You can now reboot into your new system."
        exit 0
    else
        error "nixos-install failed."
    fi
}

# Setup sops age key from password-encrypted file
setup_sops_key() {
    info "Setting up SOPS age key..."
    
    local age_key_enc="$SCRIPT_DIR/age-key.enc"
    local sops_key_dir="/root/.config/sops/age"
    local sops_key_file="$sops_key_dir/keys.txt"
    
    if [[ ! -f "$age_key_enc" ]]; then
        error "Password-encrypted age key not found at $age_key_enc"
    fi
    
    # Check if key already exists
    if [[ -f "$sops_key_file" ]]; then
        warn "SOPS key already exists at $sops_key_file"
        read -p "Overwrite? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Keeping existing key"
            return 0
        fi
    fi
    
    # Create directory
    $SUDO mkdir -p "$sops_key_dir"
    
    # Decrypt the age key (user will be prompted for password)
    info "Enter your secrets password to decrypt the age key:"
    if nix-shell -p age --run "age -d '$age_key_enc'" | $SUDO tee "$sops_key_file" > /dev/null; then
        $SUDO chmod 600 "$sops_key_file"
        success "SOPS age key installed"
    else
        error "Failed to decrypt age key. Wrong password?"
    fi
}

# Generate hardware configuration
generate_hardware_config() {
    local hostname="$1"
    local hw_config="$SCRIPT_DIR/hosts/$hostname/hardware-configuration.nix"
    
    info "Checking hardware configuration..."
    
    # Check if hardware config exists and has real content
    if [[ -f "$hw_config" ]] && grep -q "fileSystems" "$hw_config" 2>/dev/null; then
        warn "Hardware configuration already exists at $hw_config"
        read -p "Regenerate? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Keeping existing hardware configuration"
            return 0
        fi
    fi
    
    info "Generating hardware configuration..."
    $SUDO nixos-generate-config --show-hardware-config > "$hw_config"
    success "Hardware configuration generated at $hw_config"
}

# Check Tailscale status and fix if needed
fix_tailscale_if_needed() {
    info "Checking Tailscale status..."
    
    # Check if tailscaled is running and healthy
    if $SUDO systemctl is-active tailscaled &>/dev/null; then
        # Check if we can connect to it
        if tailscale status &>/dev/null; then
            success "Tailscale is already running and healthy"
            return 0
        fi
    fi
    
    # Check for corrupted state (TPM issues, etc.)
    local state_file="/var/lib/tailscale/tailscaled.state"
    if [[ -f "$state_file" ]]; then
        # Try to start tailscaled and see if it fails
        $SUDO systemctl start tailscaled 2>/dev/null || true
        sleep 2
        
        # Check if it started successfully
        if $SUDO systemctl is-active tailscaled &>/dev/null && tailscale status &>/dev/null; then
            success "Tailscale started successfully"
            return 0
        fi
        
        # If we get here, there's likely a state corruption issue
        warn "Tailscale state appears corrupted, clearing..."
        $SUDO systemctl stop tailscaled 2>/dev/null || true
        $SUDO rm -rf /var/lib/tailscale/tailscaled.state
        success "Tailscale state cleared (will re-authenticate with auth key)"
    else
        info "Fresh Tailscale installation (no existing state)"
    fi
}

# Build and switch to the new configuration
rebuild_system() {
    local hostname="$1"
    
    info "Building and switching to configuration for '$hostname'..."
    
    # Stage all files for git (flake needs them)
    cd "$SCRIPT_DIR"
    
    # Initialize git if it's not a repository
    if [ ! -d ".git" ]; then
        info "Initializing git repository in $SCRIPT_DIR..."
        git init
        git add -A
        git config user.name "refactor-gremlin"
        git config user.email "refactor-gremlin@users.noreply.github.com"
        git remote add origin git@github.com:refactor-gremlin/nixos-config.git
        success "Git initialized with remote: git@github.com:refactor-gremlin/nixos-config.git"
    else
        git add -A 2>/dev/null || warn "Failed to stage files in existing git repo"
    fi
    
    # Rebuild
    if $SUDO nixos-rebuild switch --flake "$SCRIPT_DIR#$hostname"; then
        success "System successfully rebuilt!"
    else
        error "System rebuild failed. Check the error messages above."
    fi
}

# Main installation flow
main() {
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║              NixOS First Install Script                       ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check arguments
    if [[ $# -lt 1 ]]; then
        echo "Usage: $0 <hostname>"
        echo ""
        echo "Available hosts:"
        echo "  - pc-02      (Lisa's Desktop - AMD CPU + NVIDIA)"
        echo "  - rog-strix  (Jens' Laptop - Intel CPU + NVIDIA)"
        echo "  - server-01  (Headless Server)"
        echo ""
        exit 1
    fi
    
    local hostname="$1"
    
    # Validate
    check_privileges
    validate_hostname "$hostname"
    
    info "Installing configuration for: $hostname"
    echo ""
    
    # Check if we should use disk installation mode
    if [[ -f /etc/NIXOS ]]; then
        # We are likely in a live ISO environment
        read -p "Do you want to perform a fresh DISK installation? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Ensure sops key is set up before hardware config generation
            setup_sops_key
            disk_install "$hostname"
        fi
    fi
    
    # Step 1: Setup SOPS key
    setup_sops_key
    echo ""
    
    # Step 2: Generate hardware config
    generate_hardware_config "$hostname"
    echo ""
    
    # Step 3: Clear Tailscale state if needed
    fix_tailscale_if_needed
    echo ""
    
    # Step 4: Rebuild system
    rebuild_system "$hostname"
    echo ""
    
    success "Installation complete!"
    echo ""
    info "Post-install checklist:"
    echo "  1. Reboot to ensure all services start correctly"
    echo "  2. Run 'tailscale status' to verify VPN connection"
    echo "  3. Commit any generated files: git add -A && git commit -m 'Add hardware config'"
    echo ""
}

main "$@"

