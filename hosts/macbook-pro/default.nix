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

    # Lets herdr open "machines" on this Mac itself (ssh localhost), used for
    # the Gooskens Windows DC sessions. Restricted to local connections only.
    openssh.authorizedKeys.keys = [
      ''from="127.0.0.1,::1" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvQsKbzbW9a3tncPJojcCXLjHg8aBCQCmPQVzzsRXeZ nixos''
    ];
  };

  nix-homebrew = {
    enable = true;
    user = "jens";
    enableRosetta = true;
    autoMigrate = true;
  };
}
