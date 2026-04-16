{
  config,
  lib,
  pkgs,
  ...
}: let
  cliproxy = config.myConfig.cliproxyapi;
  cliproxyBase = "http://127.0.0.1:${toString cliproxy.port}";
in {
  # Ensure the .factory directory exists
  home.activation.createFactoryDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.factory
  '';

  sops = {
    # Default secrets file
    defaultSopsFile = ../../../secrets/common.yaml;

    # Age key location (Home Manager needs this if not using system-level sops)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Define the secret we need for the template
    secrets.zai_api_key = {};
    secrets.ollama_cloud_api_key = {};

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
              "model_display_name": "GPT-5.4 [CLIProxyAPI]",
              "model": "gpt-5.4",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.4 Fast [CLIProxyAPI]",
              "model": "gpt-5.4-fast",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.4 Mini [CLIProxyAPI]",
              "model": "gpt-5.4-mini",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.3-Codex [CLIProxyAPI]",
              "model": "gpt-5.3-codex",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GPT-5.3-Codex Spark [CLIProxyAPI]",
              "model": "gpt-5.3-codex-spark",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GLM-5.1 [OpenCode Go]",
              "model": "glm-5.1",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "GLM-5 [OpenCode Go]",
              "model": "glm-5",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "Kimi K2.5 [OpenCode Go]",
              "model": "kimi-k2.5",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiMo v2 Pro [OpenCode Go]",
              "model": "mimo-v2-pro",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiMo v2 Omni [OpenCode Go]",
              "model": "mimo-v2-omni",
              "base_url": "${cliproxyBase}/v1",
              "api_key": "${cliproxy.apiKey}",
              "provider": "openai",
              "max_tokens": 131072
            },
            {
              "model_display_name": "MiniMax M2.7 [OpenCode Go]",
              "model": "opencode-go/minimax-m2.7",
              "base_url": "${cliproxyBase}",
              "api_key": "${cliproxy.apiKey}",
              "provider": "anthropic",
              "max_tokens": 131072
            },
            {
              "model_display_name": "Claude Sonnet 4.5 [CLIProxyAPI]",
              "model": "claude-sonnet-4-5-20250929",
              "base_url": "${cliproxyBase}",
              "api_key": "${cliproxy.apiKey}",
              "provider": "anthropic",
              "max_tokens": 131072
            },
            {
              "model_display_name": "Claude Opus 4.5 [CLIProxyAPI]",
              "model": "claude-opus-4-5-20251101",
              "base_url": "${cliproxyBase}",
              "api_key": "${cliproxy.apiKey}",
              "provider": "anthropic",
              "max_tokens": 131072
            }
          ]
        }
      '';
    };
  };
}
