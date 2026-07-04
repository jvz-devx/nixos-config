{
  config,
  lib,
  pkgs,
  ...
}: let
  defaultPlugin = "@opencode-ai/plugin";
  pluginPackageName = pluginSpec: let
    scoped = builtins.match "^(@[^/]+/[^@]+)(@.+)?$" pluginSpec;
    unscoped = builtins.match "^([^@]+)(@.+)?$" pluginSpec;
  in
    if scoped != null
    then builtins.elemAt scoped 0
    else if unscoped != null
    then builtins.elemAt unscoped 0
    else pluginSpec;
in {
  options.myConfig.opencode = {
    enable = lib.mkEnableOption "OpenCode AI coding agent";
    globalAgentsText = lib.mkOption {
      type = with lib.types; nullOr lines;
      default = null;
      description = "Content for the global OpenCode AGENTS.md file.";
    };
    mcp = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = {};
      example = {
        fff = {
          type = "local";
          command = ["fff-mcp"];
          enabled = true;
        };
      };
      description = "Declarative OpenCode MCP server configuration.";
    };
    permission = lib.mkOption {
      type = with lib.types; nullOr anything;
      default = null;
      example = "allow";
      description = "Global OpenCode permission policy.";
    };
    plugins = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      example = ["@example/opencode-plugin"];
      description = "List of npm packages to install as opencode plugins";
    };
  };

  config = lib.mkIf config.myConfig.opencode.enable {
    xdg.configFile."opencode/AGENTS.md" = lib.mkIf (config.myConfig.opencode.globalAgentsText != null) {
      text = config.myConfig.opencode.globalAgentsText;
    };

    xdg.configFile."opencode/opencode.json" = {
      text = builtins.toJSON ({
          "$schema" = "https://opencode.ai/config.json";
          mcp = config.myConfig.opencode.mcp;
          plugin = config.myConfig.opencode.plugins;
        }
        // lib.optionalAttrs (config.myConfig.opencode.permission != null) {
          permission = config.myConfig.opencode.permission;
        });
    };

    xdg.dataFile = {
      "opencode/package.json" = lib.mkIf (config.myConfig.opencode.plugins != [] || config.myConfig.opencode.enable) {
        text = builtins.toJSON {
          dependencies = builtins.listToAttrs (
            map (p: {
              name = pluginPackageName p;
              value = "*";
            }) (
              [defaultPlugin] ++ config.myConfig.opencode.plugins
            )
          );
        };
      };
    };
  };
}
