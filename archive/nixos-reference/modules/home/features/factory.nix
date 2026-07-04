{
  config,
  lib,
  pkgs,
  ...
}: let
  cliproxyBase = "http://chat-api.jensvanzutphen.com:8317";
  cliproxyApiKey = config.sops.placeholder.cliproxyapi_remote_api_key;
  firecrawlCliVersion = "1.15.2";
in {
  # Ensure the .factory directory exists
  home.activation.createFactoryDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.factory
  '';

  # Declaratively keep the Firecrawl CLI installed in the user's npm global prefix.
  home.activation.installFirecrawlCli = lib.hm.dag.entryAfter ["writeBoundary"] ''
    export HOME=${config.home.homeDirectory}
    export npm_config_prefix="$HOME/.npm-global"
    mkdir -p "$npm_config_prefix"

    current_version=""
    if command -v firecrawl >/dev/null 2>&1; then
      current_version="$(firecrawl --version 2>/dev/null | head -n 1 | tr -d '\r' || true)"
    fi

    if [ "$current_version" != "${firecrawlCliVersion}" ]; then
      $DRY_RUN_CMD ${pkgs.nodejs_24}/bin/npm install -g firecrawl-cli@${firecrawlCliVersion}
    fi
  '';

  sops = {
    # Default secrets file
    defaultSopsFile = ../../../secrets/common.yaml;

    # Age key location (Home Manager needs this if not using system-level sops)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Define the secret we need for the template
    secrets.zai_api_key = {};
    secrets.ollama_cloud_api_key = {};
    secrets.cliproxyapi_remote_api_key = {};

    # Template the config file
    templates."factory-config" = {
      path = "${config.home.homeDirectory}/.factory/config.json";
      content = ''
        {
          "mcp": {
            "fff": {
              "type": "local",
              "enabled": true,
              "command": ["fff-mcp"]
            },
            "firecrawl": {
              "type": "http",
              "enabled": true,
              "url": "https://mcp.firecrawl.dev/${config.sops.placeholder.zai_api_key}/v2/mcp"
            }
          },
          "custom_models": [
            {
              "model_display_name": "GLM-5.1 [Z.AI Coding Plan]",
              "model": "glm-5.1",
              "base_url": "https://api.z.ai/api/coding/paas/v4",
              "api_key": "${config.sops.placeholder.zai_api_key}",
              "provider": "generic-chat-completion-api",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GLM-5.1 [Ollama Cloud]",
              "model": "glm-5.1",
              "base_url": "https://ollama.com/v1",
              "api_key": "${config.sops.placeholder.ollama_cloud_api_key}",
              "provider": "generic-chat-completion-api",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiniMax M2.7 [Ollama Cloud]",
              "model": "minimax-m2.7",
              "base_url": "https://ollama.com/v1",
              "api_key": "${config.sops.placeholder.ollama_cloud_api_key}",
              "provider": "generic-chat-completion-api",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.5 [CLIProxyAPI]",
              "model": "gpt-5.5",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.5 Fast [CLIProxyAPI]",
              "model": "gpt-5.5-fast",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.4 Mini [CLIProxyAPI]",
              "model": "gpt-5.4-mini",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.3-Codex [CLIProxyAPI]",
              "model": "gpt-5.3-codex",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.3-Codex Spark [CLIProxyAPI]",
              "model": "gpt-5.3-codex-spark",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GLM-5.1 [OpenCode Go]",
              "model": "glm-5.1",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GLM-5 [OpenCode Go]",
              "model": "glm-5",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "Kimi K2.5 [OpenCode Go]",
              "model": "kimi-k2.5",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiMo v2 Pro [OpenCode Go]",
              "model": "mimo-v2-pro",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiMo v2 Omni [OpenCode Go]",
              "model": "mimo-v2-omni",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxyApiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiniMax M2.7 [OpenCode Go]",
              "model": "opencode-go/minimax-m2.7",
              "base_url": "${cliproxyBase}",
              "api_key": "${cliproxyApiKey}",
              "provider": "anthropic",
              "max_tokens": 131072
            }
          ]
        }
      '';
    };
  };
}
