# RustDesk remote desktop with self-hosted signal/relay server and IP whitelist.
#
# The flutter client's `rustdesk --option` CLI silently no-ops without a
# system install, so we write RustDesk2.toml directly to configure the
# client (custom rendezvous/relay/key/whitelist).
#
# The incoming-connection password must be set once via the GUI; there is no
# reliable declarative path for it (the hash is salted per-install and
# `rustdesk --password` requires privileges the flutter build does not expose).
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myConfig.programs.rustdesk;

  writeClientConfig = pkgs.writeShellScript "rustdesk-write-client-config" ''
    set -eu
    dir="$HOME/.config/rustdesk"
    mkdir -p "$dir"
    cat > "$dir/RustDesk2.toml" <<EOF
    rendezvous_server = ''\'''\'
    nat_type = 1
    serial = 0

    [options]
    custom-rendezvous-server = '${cfg.serverHost}'
    relay-server = '${cfg.serverHost}'
    key = '${cfg.serverKey}'
    whitelist = '${lib.concatStringsSep "," cfg.whitelist}'
    EOF
  '';
in {
  options.myConfig.programs.rustdesk = {
    enable = lib.mkEnableOption "RustDesk remote desktop (self-hosted server + client)";

    serverHost = lib.mkOption {
      type = lib.types.str;
      description = "Host/IP clients use to reach the self-hosted rendezvous server. Typically this machine's Tailscale IP.";
    };

    serverKey = lib.mkOption {
      type = lib.types.str;
      description = "Public key of the self-hosted server (contents of /var/lib/rustdesk/id_ed25519.pub).";
    };

    whitelist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["192.168.0.0/22" "100.64.0.0/10"];
      description = "IPs/CIDRs allowed to initiate sessions to this machine. Empty = any.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.rustdesk-server = {
      enable = true;
      openFirewall = true;
      signal = {
        enable = true;
        relayHosts = [cfg.serverHost];
        extraArgs = ["-k" "_"];
      };
      relay = {
        enable = true;
        extraArgs = ["-k" "_"];
      };
    };

    environment.systemPackages = [pkgs.rustdesk-flutter];

    systemd.user.services.rustdesk = {
      description = "RustDesk remote desktop client";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${writeClientConfig}";
        ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
