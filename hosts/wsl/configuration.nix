# NixOS-WSL configuration
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # NixOS-WSL module is already imported in flake.nix
  ];

  # Enable WSL support
  wsl.enable = true;
  wsl.defaultUser = "jens";
  wsl.useWindowsDriver = true;
  wsl.interop.register = true;
  wsl.wslConf.automount.options = "metadata,uid=1000,gid=100,umask=22,fmask=11";

  # Enable nix-ld for running unpatched binaries (important for VS Code extensions)
  programs.nix-ld.enable = true;

  # Enable profiles and options
  myConfig.profiles.development.enable = true;
  myConfig.system.locale.enable = true;
  myConfig.services.ssh.enable = true;
  myConfig.secrets.sshKeyUser = "jens";

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Nix settings
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
      trusted-users = ["root" "jens" "@wheel"];
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Hostname
  networking.hostName = "nixos-wsl";

  # Administrator rights
  security.sudo.wheelNeedsPassword = false;

  # User configuration
  users.users.jens = {
    isNormalUser = true;
    description = "Jens";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.git.config.safe.directory = "/etc/nixos";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
