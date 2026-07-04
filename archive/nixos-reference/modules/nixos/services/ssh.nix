# OpenSSH server configuration
{
  config,
  lib,
  ...
}: {
  options.myConfig.services.ssh = {
    enable = lib.mkEnableOption "OpenSSH server";
  };

  config = lib.mkIf config.myConfig.services.ssh.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "no";
      };
    };

    networking.firewall.allowedTCPPorts = [22];
  };
}
