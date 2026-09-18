{
  config,
  lib,
  pkgs,
  ...
}: let
  nzbgetConfigPath = "${config.xdg.configHome}/nzbget/nzbget.conf";
  prowlarrDataPath = "${config.home.homeDirectory}/Library/Application Support/Prowlarr";
  sonarrDataPath = "${config.home.homeDirectory}/Library/Application Support/Sonarr";
  nzbStackUp = pkgs.writeShellApplication {
    name = "nzb-stack-up";
    text = ''
      user_id=$(/usr/bin/id -u)

      for service in nzbget prowlarr sonarr; do
        /bin/launchctl kickstart "gui/$user_id/org.nix-community.home.$service"
      done

      wait_for() {
        service_name="$1"
        service_url="$2"

        for _ in {1..40}; do
          if ${pkgs.curl}/bin/curl --max-time 1 -fsS "$service_url" >/dev/null 2>&1; then
            printf '%s is ready at %s\n' "$service_name" "$service_url"
            return 0
          fi
          /bin/sleep 0.5
        done

        printf '%s did not become ready at %s\n' "$service_name" "$service_url" >&2
        return 1
      }

      wait_for NZBGet http://127.0.0.1:6789/
      wait_for Prowlarr http://127.0.0.1:9696/ping
      wait_for Sonarr http://127.0.0.1:8989/ping
    '';
  };
  nzbStackDown = pkgs.writeShellApplication {
    name = "nzb-stack-down";
    text = ''
      user_id=$(/usr/bin/id -u)

      for service in sonarr prowlarr nzbget; do
        /bin/launchctl kill SIGTERM "gui/$user_id/org.nix-community.home.$service" 2>/dev/null || true
      done

      for service in sonarr prowlarr nzbget; do
        for _ in {1..50}; do
          if ! /bin/launchctl print "gui/$user_id/org.nix-community.home.$service" 2>/dev/null \
            | /usr/bin/grep -q '^[[:space:]]*state = running$'; then
            break
          fi
          /bin/sleep 0.2
        done
      done

      for port in 8989 9696 6789; do
        for _ in {1..50}; do
          if ! /usr/sbin/lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1; then
            break
          fi
          /bin/sleep 0.2
        done
      done
    '';
  };
  nzbHealthWatch = pkgs.writeShellApplication {
    name = "nzb-health-watch";
    text = ''
      queue=$(${pkgs.curl}/bin/curl --max-time 2 -fsS http://127.0.0.1:6789/jsonrpc/listgroups 2>/dev/null) || exit 0

      # ponytail: three all-server failures means reject the release; raise it if good jobs get deleted.
      printf '%s' "$queue" \
        | ${pkgs.jq}/bin/jq -r '
            .result[]
            | select(.FailedArticles >= 3)
            | [.NZBID, .NZBName]
            | @tsv
          ' \
        | while IFS=$'\t' read -r nzb_id nzb_name; do
            ${pkgs.jq}/bin/jq -n --argjson nzb_id "$nzb_id" \
              '{method: "editqueue", params: ["GroupDelete", "", [$nzb_id]], id: 1}' \
              | ${pkgs.curl}/bin/curl --max-time 5 -fsS \
                  -H 'Content-Type: application/json' \
                  --data-binary @- \
                  http://127.0.0.1:6789/jsonrpc >/dev/null
            /bin/sleep 1
            ${pkgs.jq}/bin/jq -n --argjson nzb_id "$nzb_id" \
              '{method: "editqueue", params: ["HistoryMarkBad", "", [$nzb_id]], id: 1}' \
              | ${pkgs.curl}/bin/curl --max-time 5 -fsS \
                  -H 'Content-Type: application/json' \
                  --data-binary @- \
                  http://127.0.0.1:6789/jsonrpc >/dev/null
            printf 'Deleted %s after three articles failed across every server\n' "$nzb_name"
          done
    '';
  };
in {
  home.packages = [
    pkgs.prowlarr
    pkgs.sonarr
    nzbStackUp
    nzbStackDown
  ];

  programs.zsh.shellAliases = {
    nzb-up = "nzb-stack-up";
    nzb-down = "nzb-stack-down";
  };

  sops.secrets.nzbget_config = {
    path = nzbgetConfigPath;
    mode = "0600";
  };

  home.activation.createNzbgetMainDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.coreutils}/bin/mkdir -p \
      "${config.home.homeDirectory}/Media/NZBGet/completed/Prowlarr" \
      "${config.home.homeDirectory}/Media/NZBGet/completed/tv" \
      "${config.home.homeDirectory}/Media/TV"
  '';

  launchd.agents.nzbget = {
    enable = true;
    config = {
      ProgramArguments = [
        "/opt/homebrew/opt/nzbget/bin/nzbget"
        "-c"
        nzbgetConfigPath
        "-s"
        "-o"
        "OutputMode=Log"
        "-o"
        "ConfigTemplate=/opt/homebrew/share/nzbget/nzbget.conf"
        "-o"
        "WebDir=/opt/homebrew/share/nzbget/webui"
      ];
      KeepAlive = false;
      RunAtLoad = false;
      ProcessType = "Background";
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nzbget.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nzbget.error.log";
    };
  };

  launchd.agents.prowlarr = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.prowlarr}/bin/Prowlarr"
        "-nobrowser"
        "-data=${prowlarrDataPath}"
      ];
      KeepAlive = false;
      RunAtLoad = false;
      ProcessType = "Background";
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/prowlarr.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/prowlarr.error.log";
    };
  };

  launchd.agents.sonarr = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.sonarr}/bin/Sonarr"
        "-nobrowser"
        "-data=${sonarrDataPath}"
      ];
      KeepAlive = false;
      RunAtLoad = false;
      ProcessType = "Background";
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/sonarr.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/sonarr.error.log";
    };
  };

  launchd.agents.nzb-health-watch = {
    enable = true;
    config = {
      ProgramArguments = ["${nzbHealthWatch}/bin/nzb-health-watch"];
      RunAtLoad = true;
      StartInterval = 2;
      ProcessType = "Background";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/nzb-health-watch.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/nzb-health-watch.error.log";
    };
  };
}
