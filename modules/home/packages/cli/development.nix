{
  config,
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
  tomlFormat = pkgs.formats.toml {};
in {
  home.packages = with pkgs; [
    nodejs_24
    # Factory AI droid CLI (via nix-ai-tools flake)
    droid
    # GitHub Copilot CLI
    github-copilot-cli
    # OpenAI Codex CLI
    inputs.codex-cli.packages.${pkgs.system}.default
    # CodeRabbit CLI
    coderabbit
    # fff-mcp - fast file search MCP server for Claude Code
    fff-mcp
    # herdr - terminal-native agent multiplexer
    herdr
    # Cloudflare CLI (technical preview)
    cf
  ];

  xdg.desktopEntries.herdr = {
    name = "Herdr";
    exec = "herdr";
    icon = "utilities-terminal";
    comment = "Terminal-native agent multiplexer";
    categories = ["Development" "TerminalEmulator"];
    terminal = true;
  };

  home.file."Desktop/Herdr.desktop" = {
    executable = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Herdr
      Comment=Terminal-native agent multiplexer
      Exec=herdr
      Icon=utilities-terminal
      Terminal=true
      Categories=Development;TerminalEmulator;
    '';
  };

  xdg.configFile."codex/config.toml".source = tomlFormat.generate "codex-config.toml" {
    features.memories = true;
    approval_policy = "never";
    sandbox_mode = "danger-full-access";
    web_search = "live";
    mcp_servers.firecrawl = {
      command = "npx";
      args = ["-y" "firecrawl-mcp"];
      env = {
        FIRECRAWL_API_KEY = config.sops.placeholder.zai_api_key;
      };
    };
  };
}
