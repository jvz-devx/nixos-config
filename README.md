# ❄️ NixOS Multi-Host Configuration

[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?logo=nixos&logoColor=white)](https://nixos.org)
[![Plasma 6](https://img.shields.io/badge/Desktop-KDE%20Plasma%206-blue?logo=kde&logoColor=white)](https://kde.org/plasma-desktop/)
[![Gaming](https://img.shields.io/badge/Gaming-CachyOS%20Kernel-orange?logo=steam&logoColor=white)](https://github.com/chaotic-cx/nyx)
[![Secrets](https://img.shields.io/badge/Secrets-sops--nix-green?logo=lock&logoColor=white)](https://github.com/Mic92/sops-nix)

A sophisticated, multi-host NixOS configuration using Flakes and Home Manager. Features declarative desktop environments, gaming optimizations, and automated secrets management.

## 🚀 Key Features

- **Multi-Host Architecture**: Unified configuration for desktops, laptops, and servers.
- **KDE Plasma 6**: Declarative desktop configuration via `plasma-manager`.
- **Gaming Optimized**: CachyOS kernel via `chaotic-nyx`, NVIDIA stability tweaks, and Steam/Heroic/Lutris pre-configured.
- **Secure Secrets**: Integrated `sops-nix` with `age` encryption for sensitive data.
- **Automated ISOs**: Generate custom installation media for any host with one command.
- **Development Ready**: Comprehensive dev environments for Python, Node.js, and Rust.

## 🖥️ Managed Hosts

| Host | Description | Specs | Primary User |
|------|-------------|-------|--------------|
| `pc-02` | High-End Desktop | AMD CPU + NVIDIA GPU | Lisa |
| `rog-strix` | Gaming Laptop | Intel CPU + NVIDIA GPU (ASUS) | Jens |
| `server-01` | Headless Server | x86_64 Minimal | Admin |

## 🛠️ Project Structure

```text
.
├── flake.nix             # System entry point & input management
├── hosts/                # Host-specific hardware and overrides
│   ├── pc-02/            # Lisa's desktop configuration
│   ├── rog-strix/        # Jens' laptop (ASUS specialized)
│   └── server-01/        # Minimal server setup
├── home/                 # User-specific Home Manager configs
├── modules/              # Reusable system and user modules
│   ├── nixos/            # System-level modules (services, hardware)
│   └── home/             # User-level modules (programs, dotfiles)
├── pkgs/                 # Custom package definitions
├── overlays/             # Nixpkgs overlays and patches
└── secrets/              # Encrypted secrets via sops-nix
```

## 📥 Installation

```bash
# 1. Clone to /etc/nixos
sudo git clone https://github.com/jvz-devx/nixos-config /etc/nixos
cd /etc/nixos

# 2. Deploy using the install script
sudo ./install.sh <hostname>
```

## 🔄 Daily Workflow

```bash
# Rebuild the current system
rebuild

# Update all inputs
nix flake update

# Build a custom ISO for a host (useful for server)
nix build .#<hostname>-iso
```

## 🔐 Secrets Management

We use `sops-nix` with `age`. Your private key is stored password-encrypted in `age-key.enc`.

```bash
# Edit secrets
sops secrets/common.yaml

# Re-encrypt key after change
age -p -a -o age-key.enc /tmp/new-key.txt
```

---