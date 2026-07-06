pkgs: {
  sqlit-tui = pkgs.callPackage ./sqlit-tui.nix {};
  cf = pkgs.callPackage ./cf {};
  svelte-autofix = pkgs.callPackage ./svelte-autofix {};
}
