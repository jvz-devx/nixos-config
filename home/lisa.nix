# Home Manager configuration for lisa
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
    ../modules/home/konsole.nix

    # Specialized package modules
    ../modules/home/packages/gui/stremio.nix
    ../modules/home/packages/gui/media.nix
    ../modules/home/packages/gui/chrome.nix
    ../modules/home/packages/gui/tailscale.nix
    ../modules/home/packages/gui/gaming.nix
    ../modules/home/packages/gui/creative.nix
    ../modules/home/packages/cli/development.nix
    ../modules/home/packages/gui/communication.nix
    ../modules/home/packages/cli/base.nix
    ../modules/home/packages/gui/base.nix
  ];

  # Home Manager settings
  home = {
    username = "lisa";
    homeDirectory = "/home/lisa";
    packages = with pkgs; [
      spotify
    ];
  };

  # User-specific shell aliases
  programs.zsh.shellAliases = {
    # NixOS rebuild command for this host
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#pc-02";
    update = "nix flake update /etc/nixos";
  };

  # User-specific git config
  programs.git.settings = {
    safe.directory = "/etc/nixos";
    user.name = "Lisa";
    user.email = "lisa@example.com";  # Change to Lisa's email
    # Fix for "Bad owner or permissions on ~/.ssh/config" when running in namespaced environments (like Cursor)
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


