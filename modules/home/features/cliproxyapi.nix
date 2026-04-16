{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myConfig.cliproxyapi;
  configDir = "${config.home.homeDirectory}/.cli-proxy-api";
  configFile = "${configDir}/config.yaml";
  codexCredentialFile = "${configDir}/${cfg.codexCredentialFileName}";
in {
  options.myConfig.cliproxyapi = {
    enable = lib.mkEnableOption "CLIProxyAPI local proxy";
    port = lib.mkOption {
      type = lib.types.port;
      default = 8317;
      description = "Local CLIProxyAPI port.";
    };
    apiKey = lib.mkOption {
      type = lib.types.str;
      default = "sk-factory-droid-local";
      description = "Local API key used by local clients such as Droid and OpenCode.";
    };
    codexCredentialFileName = lib.mkOption {
      type = lib.types.str;
      default = "codex-jensvanzutphen@protonmail.com-prolite.json";
      description = "Filename for the Codex OAuth credential stored under ~/.cli-proxy-api.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../../secrets/common.yaml;
      age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      secrets.cliproxyapi_codex_credential = {
        path = codexCredentialFile;
      };
      secrets.opencode_go_api_key = {};

      templates."cliproxyapi-config" = {
        path = configFile;
        content = ''
          host: "127.0.0.1"
          port: ${toString cfg.port}

          auth-dir: "~/.cli-proxy-api"

          api-keys:
            - "${cfg.apiKey}"

          debug: false
          usage-statistics-enabled: false
          logging-to-file: false
          request-retry: 3
          nonstream-keepalive-interval: 0
          ws-auth: false

          remote-management:
            allow-remote: false
            secret-key: ""
            disable-control-panel: true

          oauth-model-alias:
            codex:
              - name: "gpt-5.4"
                alias: "gpt-5.4-fast"
                fork: true
              - name: "gpt-5.4"
                alias: "claude-opus-4-6"
                fork: true
              - name: "gpt-5.4-mini"
                alias: "claude-sonnet-4-6"
                fork: true
              - name: "gpt-5.4-mini"
                alias: "claude-haiku-4-5"
                fork: true

          claude-api-key:
            - api-key: "${config.sops.placeholder.opencode_go_api_key}"
              prefix: "opencode-go"
              base-url: "https://opencode.ai/zen/go"
              models:
                - name: "opencode-go/minimax-m2.7"
                  alias: "minimax-m2.7"

          openai-compatibility:
            - name: "opencode-go"
              base-url: "https://opencode.ai/zen/go/v1"
              api-key-entries:
                - api-key: "${config.sops.placeholder.opencode_go_api_key}"
              models:
                - name: "opencode-go/glm-5.1"
                  alias: "glm-5.1"
                - name: "opencode-go/glm-5"
                  alias: "glm-5"
                - name: "opencode-go/kimi-k2.5"
                  alias: "kimi-k2.5"
                - name: "opencode-go/mimo-v2-pro"
                  alias: "mimo-v2-pro"
                - name: "opencode-go/mimo-v2-omni"
                  alias: "mimo-v2-omni"

          payload:
            override:
              - models:
                  - name: "gpt-5.4-fast"
                    protocol: "codex"
                  - name: "claude-opus-4-6"
                    protocol: "codex"
                params:
                  service_tier: "priority"
        '';
      };
    };

    home.activation.createCliProxyApiDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${configDir}
      $DRY_RUN_CMD chmod 700 ${configDir}
    '';

    systemd.user.services.cliproxyapi = {
      Unit = {
        Description = "CLIProxyAPI local proxy";
        After = ["default.target"];
        ConditionPathExists = configFile;
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.cliproxyapi} --config ${configFile}";
        Restart = "on-failure";
        RestartSec = 5;
        WorkingDirectory = config.home.homeDirectory;
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
