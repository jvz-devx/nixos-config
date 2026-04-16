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

## 🌐 Local LAN DNS Aliases

The homelab also uses DNS-only Cloudflare records in `jensvanzutphen.com` as convenient LAN aliases for local infrastructure. These point to private RFC1918 addresses and are intended for use on the local network.

| Name | IP | Purpose |
|------|----|---------|
| `proxmox.jensvanzutphen.com` | `192.168.1.201` | Proxmox node1 |
| `proxmox2.jensvanzutphen.com` | `192.168.1.202` | Proxmox node2 |
| `node1.jensvanzutphen.com` | `192.168.1.201` | Proxmox node1 alias |
| `node2.jensvanzutphen.com` | `192.168.1.202` | Proxmox node2 alias |
| `homeassistant.jensvanzutphen.com` | `192.168.1.27` | Home Assistant VM |
| `haos.jensvanzutphen.com` | `192.168.1.27` | Home Assistant OS alias |
| `docker.jensvanzutphen.com` | `192.168.1.60` | Docker VM |
| `n8n.jensvanzutphen.com` | `192.168.1.51` | n8n VM |
| `ubuntu.jensvanzutphen.com` | `192.168.1.54` | Ubuntu desktop/VM |
| `h3s-node.jensvanzutphen.com` | `192.168.1.100` | h3s-node alias for k3s-node LXC |
| `k3s-node.jensvanzutphen.com` | `192.168.1.100` | k3s-node LXC |
| `k3s.jensvanzutphen.com` | `192.168.1.100` | k3s-node alias |
| `couchdb.jensvanzutphen.com` | `192.168.1.211` | apache-couchdb LXC |

Keep this table in sync with Cloudflare whenever LAN addresses change.

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
# Rebuild the current system (alias)
rebuild

# Dry-build (see what would be built/downloaded)
sudo nixos-rebuild dry-build --flake .

# Dry-activate (see what system changes would occur)
sudo nixos-rebuild dry-activate --flake .

# Build without applying (creates ./result link)
sudo nixos-rebuild build --flake .

# Update all inputs
nix flake update

# Build a custom ISO for a host
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