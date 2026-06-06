# MacBook Pro Setup Notes

This host is managed as `darwinConfigurations.macbook-pro` with nix-darwin,
nix-homebrew, Home Manager, and the existing `/opt/homebrew` install.

## Manual / App Store

- Codex Desktop is installed through the Mac App Store.
- ChatGPT Atlas is installed through the Mac App Store.
- Bitwarden is installed manually. The Mac App Store build is preferred for
  Touch ID unlock; browser autofill is handled by the Bitwarden browser
  extension rather than macOS system-wide AutoFill.
- Microsoft Office is installed through the Mac App Store.
- Cotabby is optional/manual until its install source and pricing are confirmed.
- VMware Fusion is manual for now because the Homebrew cask is currently disabled
  due to Broadcom authenticated downloads.
- Pear Desktop is installed through Homebrew from the upstream
  `pear-devs/pear` tap.

## Optional Fallbacks

- Rectangle: install only if Raycast Window Management is not enough.
- AltTab: install only if DockDoor is not enough.

## Post-Install Commands

```bash
bw login
bw unlock

az extension add --name azure-devops
gh auth login
az login

colima start --cpu 6 --memory 12 --disk 100

uv tool install sqlit-tui

rustup-init
rustup update

nvm install --lts
nvm use --lts
corepack enable
corepack prepare pnpm@latest --activate
```

## Activation

First activation, if `darwin-rebuild` is not available yet:

```bash
nix run nix-darwin -- switch --flake ~/nix#macbook-pro
```

After that:

```bash
darwin-rebuild switch --flake ~/nix#macbook-pro
```
