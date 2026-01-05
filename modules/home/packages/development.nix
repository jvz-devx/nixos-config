{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    nodejs_24
    # Factory AI droid CLI (via nix-ai-tools flake)
    inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.droid
    # GitHub Copilot CLI
    github-copilot-cli
  ];
}

