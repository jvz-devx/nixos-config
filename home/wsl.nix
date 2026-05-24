# Home Manager configuration for jens in WSL
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Shared home modules
    ../modules/home/base/shell.nix
    ../modules/home/base/programs.nix
    ../modules/home/features/factory.nix

    # Specialized package modules (CLI only for WSL)
    ../modules/home/packages/cli/development.nix
    ../modules/home/packages/cli/base.nix
  ];

  home.packages = with pkgs; [
    wl-clipboard # Clipboard sharing
    wsl-open # Open links in Windows browser
    tealdeer # Fast tldr
    dust # Visual disk usage
  ];

  # Modern CLI tools
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  # Home Manager settings
  home = {
    username = "jens";
    homeDirectory = "/home/jens";
  };

  # User-specific shell aliases
  programs.zsh.shellAliases = {
    # NixOS rebuild command for WSL
    rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#wsl";
    update = "nix flake update /etc/nixos";
  };

  # User-specific git config
  programs.git.settings = {
    user.name = "jvz-devx";
    user.email = "jvz-devx@users.noreply.github.com";
  };

  # Enable home-manager itself
  programs.home-manager.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}
