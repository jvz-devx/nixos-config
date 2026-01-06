# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  # example = pkgs.callPackage ./example { };
  coderabbit = pkgs.callPackage ./coderabbit.nix {};
  sqlit-tui = pkgs.callPackage ./sqlit-tui.nix {};
  smart-video-wallpaper = pkgs.kdePackages.callPackage ./smart-video-wallpaper.nix {};
}
