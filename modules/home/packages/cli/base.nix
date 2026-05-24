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
      bitwarden-cli

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
