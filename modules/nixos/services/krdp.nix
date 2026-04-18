# KRDP - KDE Remote Desktop server for Plasma 6 (RDP protocol).
#
# Exposes the running Plasma Wayland session over RDP. Runs as a systemd user
# service so it inherits the user's DBus/Wayland/PipeWire environment. Uses
# the `--plasma` flag to talk to KWin's native screencast protocol instead of
# going through XDG desktop portals (better performance on Plasma).
#
# TLS: when no certificate is supplied, krdpserver generates a temporary
# self-signed cert on each start. Clients will warn on reconnect; this is
# acceptable for personal LAN/Tailscale use.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myConfig.services.krdp;

  startScript = pkgs.writeShellScript "krdpserver-start" ''
    set -eu
    if [ ! -r "${cfg.passwordFile}" ]; then
      echo "krdp: password file not readable: ${cfg.passwordFile}" >&2
      exit 1
    fi
    password="$(cat ${cfg.passwordFile})"
    exec ${lib.getExe' pkgs.kdePackages.krdp "krdpserver"} \
      --username ${lib.escapeShellArg cfg.username} \
      --password "$password" \
      --port ${toString cfg.port} \
      --plasma
  '';
in {
  options.myConfig.services.krdp = {
    enable = lib.mkEnableOption "KRDP (KDE Remote Desktop / RDP server for Plasma 6)";

    username = lib.mkOption {
      type = lib.types.str;
      description = "Username RDP clients log in with.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      default = "/run/secrets/krdp_password";
      description = "Path to a file containing the RDP login password (must be readable by the target user).";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3389;
      description = "TCP port to listen on.";
    };

    allowedCIDRs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["192.168.0.0/16" "100.64.0.0/10"];
      description = ''
        CIDRs allowed to reach the RDP port. Uses nftables source-address
        filtering via `networking.firewall.extraInputRules`. The Tailscale
        interface is already a trusted interface, so listing its CIDR here
        is redundant but harmless.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.kdePackages.krdp];

    systemd.user.services.krdpserver = {
      description = "KRDP - KDE Remote Desktop Server";
      wantedBy = ["plasma-workspace.target"];
      partOf = ["plasma-workspace.target"];
      after = ["plasma-workspace.target"];
      serviceConfig = {
        Type = "exec";
        ExecStart = "${startScript}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };

    # Open the RDP port only for the listed source CIDRs. `extraInputRules`
    # is nftables-only; `extraCommands`/`extraStopCommands` target iptables.
    # Applying both keeps the module working regardless of which backend the
    # host uses.
    networking.firewall = lib.mkIf (cfg.allowedCIDRs != []) {
      extraInputRules = ''
        ip saddr { ${lib.concatStringsSep ", " cfg.allowedCIDRs} } tcp dport ${toString cfg.port} accept
      '';
      extraCommands = lib.concatMapStringsSep "\n" (cidr: "iptables -A nixos-fw -p tcp --dport ${toString cfg.port} -s ${cidr} -j nixos-fw-accept") cfg.allowedCIDRs;
      extraStopCommands = lib.concatMapStringsSep "\n" (cidr: "iptables -D nixos-fw -p tcp --dport ${toString cfg.port} -s ${cidr} -j nixos-fw-accept 2>/dev/null || true") cfg.allowedCIDRs;
    };
  };
}
