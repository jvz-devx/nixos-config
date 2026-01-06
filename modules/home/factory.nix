{
  config,
  lib,
  pkgs,
  ...
}: {
  # Ensure the .factory directory exists
  home.activation.createFactoryDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.factory
  '';

  sops = {
    # Default secrets file
    defaultSopsFile = ../../secrets/common.yaml;

    # Age key location (Home Manager needs this if not using system-level sops)
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Define the secret we need for the template
    secrets.zai_api_key = {};

    # Template the config file
    templates."factory-config" = {
      path = "${config.home.homeDirectory}/.factory/config.json";
      content = ''
        {
          "custom_models": [
            {
              "model_display_name": "GLM-4.7 [Z.AI Coding Plan]",
              "model": "glm-4.7",
              "base_url": "https://api.z.ai/api/coding/paas/v4",
              "api_key": "${config.sops.placeholder.zai_api_key}",
              "provider": "generic-chat-completion-api",
              "max_tokens": 131072
            }
          ]
        }
      '';
    };
  };
}
