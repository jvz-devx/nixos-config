# Home Manager configuration for jens on macOS.
{
  config,
  lib,
  pkgs,
  ...
}: let
  hasDotnet10 = pkgs ? dotnet-sdk_10;
in {
  imports = [
    ../modules/home/base/git.nix
    ../modules/home/base/ssh.nix
    ../modules/home/base/tmux.nix
    ../modules/home/base/gpg.nix
    ../modules/home/packages/cli/base.nix
  ];

  home = {
    username = "jens";
    homeDirectory = "/Users/jens";
    stateVersion = "26.05";

    sessionPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/opt/homebrew/opt/rustup/bin"
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.nvm/versions/node/bin"
    ];

    sessionVariables = {
      EDITOR = "nano";
      VISUAL = "nano";
      NVM_DIR = "$HOME/.nvm";
    };

    packages =
      (with pkgs; [
        gh
        jq
        yq-go
        ripgrep
        fd
        eza
        bat
        go
        bun
        pnpm
      ])
      ++ lib.optionals hasDotnet10 [
        pkgs.dotnet-sdk_10
      ];
  };

  programs.home-manager.enable = true;

  home.file.".docker/cli-plugins/docker-compose" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/docker-compose";
    executable = true;
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "npm"
        "fzf"
        "zoxide"
        "direnv"
      ];
    };

    shellAliases = {
      ll = "eza -la";
      cat = "bat";
      grep = "rg";
      rebuild-mac = "darwin-rebuild switch --flake ~/nix#macbook-pro";
      update-mac = "cd ~/nix && nix flake update && darwin-rebuild switch --flake .#macbook-pro";
    };

    initContent = ''
      if [[ -d /opt/homebrew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      if [[ -s /opt/homebrew/opt/nvm/nvm.sh ]]; then
        mkdir -p "$NVM_DIR"
        . /opt/homebrew/opt/nvm/nvm.sh
      fi
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git.settings = {
    user.name = "jvz-devx";
    user.email = "jvz-devx@users.noreply.github.com";
    init.defaultBranch = "main";
    pull.rebase = lib.mkForce false;
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
      identitiesOnly = true;
      addKeysToAgent = "yes";
    };
  };
}
