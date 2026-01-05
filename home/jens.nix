# Home Manager configuration for jens
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Shared home modules
    ../modules/home/shell.nix
    ../modules/home/programs.nix
    ../modules/home/plasma.nix
    ../modules/home/packages.nix
    ../modules/home/factory.nix

    # Specialized package modules
    ../modules/home/packages/stremio.nix
    ../modules/home/packages/chrome.nix
    ../modules/home/packages/tailscale.nix
    ../modules/home/packages/gaming.nix
    ../modules/home/packages/creative.nix
    ../modules/home/packages/development.nix
    ../modules/home/packages/communication.nix
  ];

  # Home Manager settings
  home = {
    username = "jens";
    homeDirectory = "/home/jens";
  };

  # User-specific shell aliases
  programs.zsh.shellAliases = {
    # NixOS rebuild command for this host
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#rog-strix";
    update = "nix flake update /etc/nixos";
    # Custom aliases
    crr = "coderabbit review --plain --uncommitted";
  };

  # User-specific git config
  programs.git.settings = {
    user.name = "refactor-gremlin";
    user.email = "refactor-gremlin@users.noreply.github.com";
    # Fix for "Bad owner or permissions on ~/.ssh/config" when running in namespaced environments (like Cursor)
    # This bypasses the SSH config file for Git operations and specifies the identity file directly.
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

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}


