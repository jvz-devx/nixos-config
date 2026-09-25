{
  lib,
  pkgs,
  ...
}: {
  home.packages =
    (with pkgs; [
      # Basic CLI tools
      nano
      tmux
      pandoc # Document converter (includes CLI)
      poppler-utils # PDF inspection and conversion tools
      bitwarden-cli

      # AI coding tools
      # Version is pinned ahead of nixpkgs by the overlay in overlays/default.nix;
      # see pkgs/claude-code/README.md for how to bump it.
      claude-code

      # Development tools used by Gooskens Cloud
      protobuf
      grpcurl
      fswatch
      imagemagick
      libavif

      # Binary and .NET assembly inspection
      ghidra
      ilspycmd

      # Spell checking
      hunspell
      hunspellDicts.en_US
      hunspellDicts.nl_NL
    ])
    ++ lib.optionals (pkgs ? pokemon-colorscripts) [
      # Fun terminal tools
      pkgs.pokemon-colorscripts
    ];
}
