# SOPS secrets management configuration
# Configures sops-nix for decrypting secrets at activation time
{ config, lib, ... }: {
  options.myConfig.secrets = {
    enable = lib.mkEnableOption "SOPS secrets management";
    
    sshKeyUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Username to deploy SSH key for (null to skip SSH key deployment)";
    };
  };

  config = lib.mkIf config.myConfig.secrets.enable {
    # Configure sops-nix
    sops = {
      # Default secrets file (shared across all hosts)
      defaultSopsFile = ../../../secrets/common.yaml;

      # Age key location - this is where you decrypt your password-protected key to
      age.keyFile = "/root/.config/sops/age/keys.txt";

      # Secrets to decrypt
      secrets = {
        # Tailscale authentication key
        tailscale_auth_key = {
          key = "tailscale_auth_key";
          mode = "0400";
        };

        # NAS password for FTP mount
        nas_password = {
          key = "nas_password";
          mode = "0400";
        };

        # z.ai API key
        zai_api_key = {
          key = "zai_api_key";
          mode = "0440";
          group = "wheel";
        };

        # Bitwarden API credentials (for CLI auto-login)
        bitwarden_client_id = {
          key = "bitwarden_client_id";
          mode = "0440";
          group = "wheel";
        };

        bitwarden_client_secret = {
          key = "bitwarden_client_secret";
          mode = "0440";
          group = "wheel";
        };

        # SSH private key (deployed to user's .ssh directory)
        ssh_private_key = {
          key = "ssh_private_key";
          mode = "0600";
          owner = if config.myConfig.secrets.sshKeyUser != null then config.myConfig.secrets.sshKeyUser else "root";
        };

        # SSH public key
        ssh_public_key = {
          key = "ssh_public_key";
          mode = "0644";
          owner = if config.myConfig.secrets.sshKeyUser != null then config.myConfig.secrets.sshKeyUser else "root";
        };

        # GPG private key
        gpg_private_key = {
          key = "gpg_private_key";
          mode = "0400";
          owner = if config.myConfig.secrets.sshKeyUser != null then config.myConfig.secrets.sshKeyUser else "root";
        };
      };
    };

    # Create symlinks in user's .ssh directory
    system.activationScripts.ssh-key-symlinks = lib.mkIf (config.myConfig.secrets.sshKeyUser != null) (let
      user = config.myConfig.secrets.sshKeyUser;
      homeDir = "/home/${user}";
    in ''
      echo "Setting up SSH key symlinks for ${user}..."
      mkdir -p ${homeDir}/.ssh
      chmod 700 ${homeDir}/.ssh
      
      # Create symlinks to the decrypted secrets
      ln -sf /run/secrets/ssh_private_key ${homeDir}/.ssh/id_ed25519
      ln -sf /run/secrets/ssh_public_key ${homeDir}/.ssh/id_ed25519.pub
      
      # Ensure ownership of the directory and the symlinks we created
      chown ${user}:users ${homeDir}/.ssh
      chown -h ${user}:users ${homeDir}/.ssh/id_ed25519 ${homeDir}/.ssh/id_ed25519.pub
      
      echo "SSH key symlinks created in ${homeDir}/.ssh/"
    '');

    # Import GPG key for the user
    system.activationScripts.gpg-key-import = lib.mkIf (config.myConfig.secrets.sshKeyUser != null) (let
      user = config.myConfig.secrets.sshKeyUser;
    in ''
      if [ -f /run/secrets/gpg_private_key ]; then
        echo "Importing GPG key for ${user}..."
        # Run as the user to import into their keyring
        /run/current-system/sw/bin/sudo -u ${user} /run/current-system/sw/bin/gpg --import /run/secrets/gpg_private_key || true
      fi
    '');
  };
}

