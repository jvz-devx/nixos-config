{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myConfig.remoteOpencode;
  remoteConfigDir = "${config.home.homeDirectory}/.remote-opencode";
  remoteCacheDir = "${remoteConfigDir}/npm-cache";
  remoteDataFile = "${remoteConfigDir}/data.json";
  remoteConfigTemplate = config.sops.templates."remote-opencode-config";
  servicePath = lib.makeBinPath [
    pkgs.bash
    pkgs.coreutils
    pkgs.git
    pkgs.gnumake
    pkgs.nodejs_22
    pkgs.opencode
    pkgs.pkg-config
    pkgs.python3
    pkgs.stdenv.cc
  ];
in {
  options.myConfig.remoteOpencode = {
    enable = lib.mkEnableOption "remote-opencode Discord bridge";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      remote_opencode_discord_token = {};
      remote_opencode_client_id = {};
      remote_opencode_guild_id = {};
      remote_opencode_allowed_user_id = {};
    };

    sops.templates."remote-opencode-config" = {
      path = "${remoteConfigDir}/config.json";
      content = ''
        {
          "bot": {
            "discordToken": "${config.sops.placeholder.remote_opencode_discord_token}",
            "clientId": "${config.sops.placeholder.remote_opencode_client_id}",
            "guildId": "${config.sops.placeholder.remote_opencode_guild_id}"
          },
          "allowedUserIds": [
            "${config.sops.placeholder.remote_opencode_allowed_user_id}"
          ]
        }
      '';
    };

    home.activation.createRemoteOpenCodeDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${remoteConfigDir}
      $DRY_RUN_CMD mkdir -p ${remoteCacheDir}
      $DRY_RUN_CMD chmod 700 ${remoteConfigDir}
      $DRY_RUN_CMD chmod 700 ${remoteCacheDir}

      if [ ! -f ${remoteDataFile} ]; then
        $DRY_RUN_CMD touch ${remoteDataFile}
        $DRY_RUN_CMD chmod 600 ${remoteDataFile}
      fi
    '';

    systemd.user.services.remote-opencode = {
      Unit = {
        Description = "remote-opencode Discord bridge";
        After = ["default.target"];
        ConditionPathExists = remoteConfigTemplate.path;
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.nodejs_22 "npx"} --cache ${remoteCacheDir} -y remote-opencode start";
        Restart = "on-failure";
        RestartSec = 5;
        WorkingDirectory = config.home.homeDirectory;
        Environment = [
          "PATH=${servicePath}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
        ];
      };
      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
