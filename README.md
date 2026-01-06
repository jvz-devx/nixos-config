# NixOS Multi-Host Configuration

Personal NixOS + Home Manager configuration for multiple machines with automatic secrets management.

## Hosts

| Host | Description | User |
|------|-------------|------|
| `pc-02` | Desktop - AMD CPU + NVIDIA GPU | Lisa |
| `rog-strix` | ROG Strix G16 Laptop - Intel CPU + NVIDIA GPU | Jens |
| `server-01` | Headless Server | - |

## Quick Install (New Machine)

```bash
# 1. Boot into NixOS installer or minimal system

# 2. Clone this repo
git clone https://github.com/jvz-devx/nixos-config /etc/nixos
cd /etc/nixos

# 3. Run the install script (will prompt for secrets password)
./install.sh <hostname>

# Example:
./install.sh pc-02
```

The install script will:
1. Decrypt your secrets key (prompts for password)
2. Generate hardware configuration
3. Build and switch to the configuration
4. Auto-authenticate Tailscale

## Structure

```
.
├── flake.nix                 # Main entry point
├── install.sh                # First-time install script
├── age-key.enc               # Password-encrypted secrets key
├── secrets/
│   └── common.yaml           # Encrypted secrets (Tailscale, etc.)
├── .sops.yaml                # Secrets encryption config
├── hosts/
│   ├── pc-02/                # Lisa's desktop
│   ├── rog-strix/            # Jens' laptop
│   └── server-01/            # Headless server
├── home/
│   ├── lisa.nix              # Lisa's home-manager config
│   └── jens.nix              # Jens' home-manager config
├── modules/
│   ├── nixos/                # System modules
│   └── home/                 # Home-manager modules
├── overlays/                 # Package overlays
└── pkgs/                     # Custom packages
```

## Daily Usage

```bash
# Rebuild system (includes home-manager)
sudo nixos-rebuild switch --flake /etc/nixos#<hostname>

# Or use the alias (already configured)
rebuild

# Update flake inputs
nix flake update

# Build without switching (test)
nixos-rebuild build --flake /etc/nixos#<hostname>
```

## Secrets Management

Secrets are encrypted with [sops-nix](https://github.com/Mic92/sops-nix) using age encryption.

### How It Works

1. Your age key is encrypted with a password → `age-key.enc`
2. Secrets are encrypted with the age key → `secrets/common.yaml`
3. On new machines: enter password → decrypt age key → NixOS decrypts secrets

### Add/Edit Secrets

   ```bash
# Edit secrets (opens in $EDITOR)
nix-shell -p sops --run 'sops /etc/nixos/secrets/common.yaml'
   ```

### Regenerate Age Key (if compromised)

   ```bash
# Generate new key
nix-shell -p age --run 'age-keygen -o /tmp/new-key.txt'

# Update .sops.yaml with new public key
# Then re-encrypt all secrets:
nix-shell -p sops --run 'sops updatekeys secrets/common.yaml'

# Encrypt the new key with password
nix-shell -p age --run 'age -p -a -o age-key.enc /tmp/new-key.txt'

# Install for current machine
sudo cp /tmp/new-key.txt /root/.config/sops/age/keys.txt
rm /tmp/new-key.txt
   ```

## Building ISOs

   ```bash
# Build installation ISO for a host
nix build .#pc-02-iso
nix build .#rog-strix-iso
nix build .#server-01-iso

# ISO will be at: result/iso/*.iso
   ```

## See Also

- [GPU_MODE_GUIDE.md](GPU_MODE_GUIDE.md) — NVIDIA GPU mode switching (laptop)
