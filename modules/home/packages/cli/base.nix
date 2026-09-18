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
      # Development tools used by Gooskens Cloud
      protobuf
      grpcurl
      fswatch
      imagemagick
      libavif

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
