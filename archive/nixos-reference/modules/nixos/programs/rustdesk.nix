# RustDesk remote desktop — split into two independent roles:
#
#   - `client.enable`: install the flutter client and write `RustDesk2.toml`
#     pointing at a (possibly remote) rendezvous/relay server.
#   - `server.enable`: run the self-hosted signal (`hbbs`) + relay (`hbbr`)
#     pair on this host and open the firewall.
#
# The roles are independent so a host can be client-only (pointing at a
# remote hbbs/hbbr — e.g. one running in the homelab k3s cluster), or
# server-only, or both.
#
# The flutter client's `rustdesk --option` CLI silently no-ops without a
# system install, so we write RustDesk2.toml directly to configure the
# client (custom rendezvous/relay/key/whitelist).
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
    custom-rendezvous-server = '${cfg.client.serverHost}'
    relay-server = '${cfg.client.serverHost}'
    key = '${cfg.client.serverKey}'
    whitelist = '${lib.concatStringsSep "," cfg.client.whitelist}'
    EOF
  '';
in {
  options.myConfig.programs.rustdesk = {
    client = {
      enable = lib.mkEnableOption "RustDesk flutter client (points at a rendezvous/relay server)";

      serverHost = lib.mkOption {
        type = lib.types.str;
        description = "Host/IP the client uses to reach the rendezvous/relay server.";
      };

      serverKey = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Public key of the rendezvous server (contents of the server's
          `id_ed25519.pub`). May be left empty to deploy the client before
          the server has generated its keypair; a build-time warning is
          emitted in that case and sessions will not establish until the
          key is filled in.
        '';
      };

      whitelist = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["192.168.0.0/22" "100.64.0.0/10"];
        description = "IPs/CIDRs allowed to initiate sessions to this machine. Empty = any.";
      };
    };

    server = {
      enable = lib.mkEnableOption "RustDesk self-hosted server (hbbs signal + hbbr relay)";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.client.enable {
      # NOTE: the incoming-connection password must be set once via the GUI;
      # there is no reliable declarative path for it (the hash is salted
      # per-install and `rustdesk --password` requires privileges the
      # flutter build does not expose).
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

      # Surface an evaluation-time warning when the server pubkey hasn't been
      # filled in yet. Uses the `warnings` NixOS option (deferred) rather than
      # `lib.warnIf` around the config block to avoid infinite recursion
      # during option merging.
      warnings = lib.optional (cfg.client.serverKey == "") ''
        myConfig.programs.rustdesk.client.serverKey is empty — RustDesk sessions will not establish until the server's public key is provided.
      '';
    })

    (lib.mkIf cfg.server.enable {
      # Signal (hbbs) + relay (hbbr). `-k _` disables key-based auth on the
      # server side; clients still pin the server's ed25519 pubkey via their
      # `key = ...` option, so this is not as open as it sounds.
      services.rustdesk-server = {
        enable = true;
        openFirewall = true;
        signal = {
          enable = true;
          extraArgs = ["-k" "_"];
        };
        relay = {
          enable = true;
          extraArgs = ["-k" "_"];
        };
      };
    })
  ];
}
