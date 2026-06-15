{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/macos-defaults.nix
    ../../modules/darwin/homebrew.nix
  ];

  networking.hostName = "macbook-pro";
  networking.localHostName = "macbook-pro";
  networking.computerName = "MacBook Pro";

  nixpkgs.overlays = [
    inputs.self.overlays.additions
    inputs.self.overlays.modifications
    inputs.self.overlays.stable-packages
  ];

  users.users.jens = {
    name = "jens";
    home = "/Users/jens";
    shell = pkgs.zsh;
  };

  nix-homebrew = {
    enable = true;
    user = "jens";
    enableRosetta = true;
    autoMigrate = true;
  };
}
