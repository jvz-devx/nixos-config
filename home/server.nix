# Home Manager configuration for server admin
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Shared CLI modules
    ../modules/home/shell.nix
    ../modules/home/programs.nix
    ../modules/home/factory.nix

    # Specialized CLI package modules (No GUI modules)
    ../modules/home/packages/cli/development.nix
    ../modules/home/packages/cli/base.nix
  ];

  # Home Manager settings
  home = {
    username = "admin";
    homeDirectory = "/home/admin";
  };

  # User-specific shell aliases
  programs.zsh.shellAliases = {
    # NixOS rebuild command for the server
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#server-01";
    update = "nix flake update /etc/nixos";
  };

  # User-specific git config
  programs.git.settings = {
    user.name = "jvz-devx";
    user.email = "jvz-devx@users.noreply.github.com";
    core.sshCommand = "ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -F /dev/null";
  };

  # User-specific SSH config
  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
      identitiesOnly = true;
      addKeysToAgent = "yes";
    };
  };

  # Enable home-manager itself
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
