# NAS mount configuration
# Mounts the NAS FTP share to /mnt/nas using curlftpfs
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.services.nas = {
    enable = lib.mkEnableOption "NAS FTP mount";
    host = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "NAS IP address";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "admin";
      description = "NAS username";
    };
    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/nas";
      description = "Local mount point";
    };
  };

  config = lib.mkIf config.myConfig.services.nas.enable {
    # Ensure GVFS is enabled as requested
    services.gvfs.enable = true;

    # rclone is much more reliable than curlftpfs for mounting FTP
    environment.systemPackages = [pkgs.rclone];

    # Create the mount point
    systemd.tmpfiles.rules = [
      "d ${config.myConfig.services.nas.mountPoint} 0755 root root -"
    ];

    # Systemd service for rclone mount
    systemd.services.nas-mount = {
      description = "Mount NAS FTP share using rclone";
      after = ["network-online.target" "sops-install-secrets.service"];
      wants = ["network-online.target"];
      wantedBy = ["multi-user.target"];

      # Use environment variables to pass secrets to rclone
      serviceConfig = {
        Type = "notify";
        # Path for rclone's temp files
        RuntimeDirectory = "rclone";
        # Cache for rclone
        CacheDirectory = "rclone";

        ExecStart = "${pkgs.bash}/bin/bash -c 'export RCLONE_FTP_PASS=$(${pkgs.rclone}/bin/rclone obscure $(cat ${config.sops.secrets.nas_password.path})) && ${pkgs.rclone}/bin/rclone mount :ftp: ${config.myConfig.services.nas.mountPoint} --ftp-host ${config.myConfig.services.nas.host} --ftp-user ${config.myConfig.services.nas.user} --ftp-port 21 --allow-other --vfs-cache-mode full --vfs-cache-max-age 24h --vfs-read-ahead 128M --no-checksum --transfers 8 --daemon-timeout 10m --volname NAS --config /dev/null --cache-dir /var/cache/rclone'";
        ExecStop = "${pkgs.util-linux}/bin/umount -l ${config.myConfig.services.nas.mountPoint}";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
