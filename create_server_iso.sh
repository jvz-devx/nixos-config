#!/usr/bin/env bash
# create_server_iso.sh
# Securely builds the server ISO by temporarily injecting the SOPS password.

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

ISO_SUPPORT_FILE="modules/nixos/system/iso-support.nix"
PLACEHOLDER="TEMP_ISO_PASSWORD"

# 1. Decrypt the password from SOPS
info "Decrypting NAS password from SOPS..."
REAL_PASSWORD=$(sops -d --extract '["nas_password"]' secrets/common.yaml)

if [ -z "$REAL_PASSWORD" ]; then
    error "Failed to decrypt password. Make sure your age key is set up."
fi

# 2. Patch the file (temporarily)
info "Temporarily patching $ISO_SUPPORT_FILE..."
# Use a different delimiter for sed in case the password contains /
sed -i "s|$PLACEHOLDER|$REAL_PASSWORD|g" "$ISO_SUPPORT_FILE"

# 3. Build the ISO
info "Building server-01-iso..."
if nix build ".#server-01-iso"; then
    success "Build successful! ISO is at ./result"
else
    # Ensure we revert even on failure
    sed -i "s|$REAL_PASSWORD|$PLACEHOLDER|g" "$ISO_SUPPORT_FILE"
    error "Nix build failed."
fi

# 4. Revert the patch
info "Reverting changes to $ISO_SUPPORT_FILE..."
sed -i "s|$REAL_PASSWORD|$PLACEHOLDER|g" "$ISO_SUPPORT_FILE"

success "Done. Nix files are clean."

