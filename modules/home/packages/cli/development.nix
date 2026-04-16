{
  pkgs,
  inputs,
  ...
}: let
  nixAiToolsSrc = inputs.nix-ai-tools;
  nixAiWrapBuddy = pkgs.callPackage "${nixAiToolsSrc}/packages/wrapBuddy/package.nix" {};
  droid = pkgs.callPackage "${nixAiToolsSrc}/packages/droid/package.nix" {
    wrapBuddy = nixAiWrapBuddy;
    inherit (pkgs) versionCheckHook;
  };
in {
  home.packages = with pkgs; [
    nodejs_24
    # Factory AI droid CLI (via nix-ai-tools flake)
    droid
    # GitHub Copilot CLI
    github-copilot-cli
    # CodeRabbit CLI
    coderabbit
    # fff-mcp - fast file search MCP server for Claude Code
    fff-mcp
    # CLIProxyAPI local model proxy
    cliproxyapi
  ];
}
