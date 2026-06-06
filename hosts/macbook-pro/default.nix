{pkgs, ...}: {
  imports = [
    ../../modules/darwin/system.nix
    ../../modules/darwin/macos-defaults.nix
    ../../modules/darwin/homebrew.nix
  ];

  networking.hostName = "macbook-pro";
  networking.localHostName = "macbook-pro";
  networking.computerName = "MacBook Pro";

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
