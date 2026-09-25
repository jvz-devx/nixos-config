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

## macshot (private fork)

macshot replaces Shottr. It runs from a private fork,
[`jvz-devx/macshot`](https://github.com/jvz-devx/macshot), which is upstream
`main` plus two commits:

- [sw33tLie/macshot#349](https://github.com/sw33tLie/macshot/pull/349): captures
  displays one at a time, starting with the one under the cursor, which fixes
  the multi-display capture delay (issue #348, still open upstream).
- Sparkle auto-update checks are turned off, so upstream releases can't replace
  the build and drop the fix.

GitHub Actions is disabled on the fork. Upstream's test workflow would
otherwise run on billed macOS runners on every push.

### Install

`modules/home/features/macshot.nix` pins the fork revision in `macshotRev` and
provides `macshot-fork-install`. The script clones the fork into
`~/.cache/macshot-fork`, builds it with Xcode, re-signs it and installs it to
`/Applications/macshot.app`. Home Manager activation runs it only when the
pinned revision changes or the app is missing. A failed build prints a warning
and doesn't stop the switch.

Xcode must be installed, and `gh` must be logged in so the private fork can be
cloned. To rebuild by hand, run `macshot-fork-install`.

### Hotkeys

Hammerspoon (`home/jens-darwin.nix`) maps Shottr's old hotkeys to macshot URL
actions:

| Hotkey | Action |
|---|---|
| Hyper+S | `macshot://capture` (area) |
| ⌘⇧1 | `macshot://capture-fullscreen` |
| ⌃⌥⌘O | `macshot://ocr` |

macshot also registers its own ⌘⇧ defaults (X, F, R, H, T, S). They're stored
in the app's sandbox container, so Nix doesn't manage them. Change them in
macshot's settings.

### Signing and Screen Recording

The build is re-signed with a self-signed identity called
`Jens Local Code Signing` from the login keychain. The Screen Recording grant
is tied to that certificate rather than each build's hash, so it survives
rebuilds. The identity isn't in Nix or sops. The private key lives only in the
login keychain.

On a new Mac, or if the identity is gone, the script installs an ad hoc build
instead, and each rebuild needs a new grant. To recreate the identity:

```bash
cat > /tmp/cs.cnf <<'CNF'
[req]
distinguished_name = dn
x509_extensions = ext
prompt = no
[dn]
CN = Jens Local Code Signing
[ext]
basicConstraints = critical,CA:false
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectKeyIdentifier = hash
CNF
cd "$(mktemp -d)" && umask 077
/usr/bin/openssl req -x509 -newkey rsa:2048 -nodes -keyout key.pem \
  -out cert.pem -days 3650 -config /tmp/cs.cnf
pw=$(/usr/bin/openssl rand -hex 16)
/usr/bin/openssl pkcs12 -export -inkey key.pem -in cert.pem \
  -name "Jens Local Code Signing" -out id.p12 -passout "pass:$pw"
security import id.p12 -k ~/Library/Keychains/login.keychain-db -P "$pw" \
  -T /usr/bin/codesign
rm -f key.pem id.p12
macshot-fork-install
```

`security find-identity -p codesigning` lists the identity as
`CSSMERR_TP_NOT_TRUSTED`. That's expected, and `codesign` still accepts it.

If macshot says Screen Recording isn't granted while System Settings shows it
on, the stored grant belongs to a different signature, such as upstream's
Developer ID build or an older ad hoc build. Clear it and grant it again:

```bash
tccutil reset ScreenCapture com.sw33tlie.macshot.macshot
open /Applications/macshot.app
```

macOS only applies a new grant after the app restarts, so choose
**Quit & Reopen** when asked.

### Updating to a newer upstream

```bash
git clone https://github.com/jvz-devx/macshot.git && cd macshot
git remote add upstream https://github.com/sw33tLie/macshot.git
git fetch upstream --tags
git rebase upstream/main          # keep the #349 and Sparkle commits on top
git push --force-with-lease origin main
git push origin --tags
```

Then set `macshotRev` in `modules/home/features/macshot.nix` to the new `main`
commit and run `darwin-rebuild switch`. If upstream merges #349, drop that
commit during the rebase.
