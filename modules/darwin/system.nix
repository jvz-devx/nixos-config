{pkgs, ...}: {
  # Determinate Nix owns the daemon and nix.conf on this Mac.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  programs.zsh.enable = true;

  environment = {
    shells = [pkgs.zsh];
    systemPackages = with pkgs; [
      git
      vim
      curl
    ];
    variables = {
      EDITOR = "nano";
      VISUAL = "nano";
    };
  };

  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

  system.activationScripts.enableRemoteLogin.text = ''
    echo "Enabling macOS Remote Login (SSH)..."
    /usr/sbin/systemsetup -setremotelogin on >/dev/null
  '';

  system = {
    primaryUser = "jens";
    stateVersion = 6;
  };
}
