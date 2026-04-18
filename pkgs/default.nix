# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  coderabbit = pkgs.callPackage ./coderabbit.nix {};
  sqlit-tui = pkgs.callPackage ./sqlit-tui.nix {};
  smart-video-wallpaper = pkgs.kdePackages.callPackage ./smart-video-wallpaper.nix {};
  fff-mcp = pkgs.callPackage ./fff-mcp.nix {};
  t3-code = pkgs.callPackage ./t3-code.nix {};
  depot-cli = pkgs.callPackage ./depot-cli.nix {};
  cmux-linux-bin = pkgs.callPackage ./cmux-linux-bin.nix {};
  cliproxyapi = pkgs.callPackage ./cliproxyapi.nix {};
  paseo = pkgs.callPackage ./paseo.nix {};
  cf = pkgs.callPackage ./cf {};
}
