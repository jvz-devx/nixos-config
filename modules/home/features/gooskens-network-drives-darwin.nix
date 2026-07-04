{
  config,
  lib,
  pkgs,
  ...
}: let
  gooskensNetworkDrives = [
    {
      letter = "F";
      mountName = "ProgHGL";
      secretName = "gooskens_smb_prog_hgl_url";
    }
    {
      letter = "G";
      mountName = "datahgl";
      secretName = "gooskens_smb_datahgl_url";
    }
    {
      letter = "H";
      mountName = "ProgMD";
      secretName = "gooskens_smb_prog_md_url";
    }
    {
      letter = "I";
      mountName = "datamd";
      secretName = "gooskens_smb_datamd_url";
    }
    {
      letter = "J";
      mountName = "ProgHLM";
      secretName = "gooskens_smb_prog_hlm_url";
    }
    {
      letter = "K";
      mountName = "datahlm";
      secretName = "gooskens_smb_datahlm_url";
    }
    {
      letter = "L";
      mountName = "datagooskens";
      secretName = "gooskens_smb_datagooskens_url";
    }
  ];

  mountScriptPath = "${config.xdg.configHome}/sops-nix/secrets/rendered/mount-gooskens-network-drives";
  mountScriptLauncher = pkgs.writeShellScript "launch-gooskens-network-drives" ''
    set -u

    if [ ! -x ${lib.escapeShellArg mountScriptPath} ]; then
      printf 'Mount script is not available yet: %s\n' ${lib.escapeShellArg mountScriptPath} >&2
      exit 0
    fi

    exec ${lib.escapeShellArg mountScriptPath}
  '';
in {
  sops = {
    defaultSopsFile = ../../../secrets/common.yaml;
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    secrets = lib.listToAttrs (
      map (drive: lib.nameValuePair drive.secretName {}) gooskensNetworkDrives
    );

    templates."mount-gooskens-network-drives" = {
      path = mountScriptPath;
      mode = "0700";
      content = ''
        #!${pkgs.bash}/bin/bash
        set -u

        mount_is_healthy() {
          local mount_point="$1"

          # macOS can keep a dead smbfs mount entry after the network/VPN drops.
          # A plain stat/ls may hang, so run the probe with a short alarm.
          ${pkgs.python3}/bin/python3 - "$mount_point" <<'PY'
        import os
        import signal
        import sys

        path = sys.argv[1]

        def timeout(_signum, _frame):
            raise TimeoutError

        signal.signal(signal.SIGALRM, timeout)
        signal.alarm(5)
        try:
            os.listdir(path)
        except Exception:
            sys.exit(1)
        else:
            sys.exit(0)
        finally:
            signal.alarm(0)
        PY
        }

        smb_url_is_reachable() {
          local url="$1"

          ${pkgs.python3}/bin/python3 - "$url" <<'PY'
        import signal
        import socket
        import sys
        from urllib.parse import urlparse

        url = sys.argv[1]
        host = urlparse(url).hostname

        if not host:
            sys.exit(1)

        def timeout(_signum, _frame):
            raise TimeoutError

        signal.signal(signal.SIGALRM, timeout)
        signal.alarm(3)
        try:
            connection = socket.create_connection((host, 445), timeout=2)
        except Exception:
            sys.exit(1)
        else:
            connection.close()
            sys.exit(0)
        finally:
            signal.alarm(0)
        PY
        }

        unmount_share() {
          local mount_point="$1"

          /sbin/umount "$mount_point" 2>/dev/null \
            || /sbin/umount -f "$mount_point" 2>/dev/null \
            || /usr/sbin/diskutil unmount force "$mount_point" >/dev/null 2>&1
        }

        remove_stale_mount_point() {
          local mount_point="$1"

          if [ -d "$mount_point" ]; then
            /bin/rmdir "$mount_point" 2>/dev/null \
              || {
                /bin/chmod u+rwx "$mount_point" 2>/dev/null \
                  && /bin/rmdir "$mount_point" 2>/dev/null
              } \
              || /usr/bin/sudo -n /bin/rmdir "$mount_point" 2>/dev/null \
              || true
          fi
        }

        mount_share() {
          local mount_name="$1"
          local url="$2"
          local mount_point="/Volumes/$mount_name"
          local mount_line

          mount_line=$(/sbin/mount | /usr/bin/grep -F " on $mount_point " || true)

          if [ -n "$mount_line" ]; then
            if printf '%s\n' "$mount_line" | /usr/bin/grep -Fq '//adminje@'; then
              if mount_is_healthy "$mount_point"; then
                return 0
              fi

              printf 'Remounting %s because the existing smbfs mount is not responding\n' "$mount_point" >&2
            else
              printf 'Remounting %s because it is not mounted as adminje: %s\n' "$mount_point" "$mount_line" >&2
            fi

            if ! unmount_share "$mount_point"; then
              printf 'Failed to unmount %s; will retry later\n' "$mount_point" >&2
              return 0
            fi
          fi

          if ! smb_url_is_reachable "$url"; then
            if [ "''${GOOSKENS_MOUNT_DEBUG:-0}" = "1" ]; then
              printf 'Skipping %s because its SMB endpoint is not reachable\n' "$mount_name" >&2
            fi
            return 0
          fi

          remove_stale_mount_point "$mount_point"

          if ! /usr/bin/osascript -e "mount volume \"$url\"" >/dev/null 2>&1; then
            printf 'Failed to mount /Volumes/%s\n' "$mount_name" >&2
          fi

          return 0
        }

        ${lib.concatMapStringsSep "\n" (drive: "mount_share ${lib.escapeShellArg drive.mountName} \"${config.sops.placeholder.${drive.secretName}}\"") gooskensNetworkDrives}
      '';
    };
  };

  home.file = lib.listToAttrs (
    map (drive:
      lib.nameValuePair "Mounts/${drive.letter}" {
        source = config.lib.file.mkOutOfStoreSymlink "/Volumes/${drive.mountName}";
      })
    gooskensNetworkDrives
  );

  launchd.agents.gooskens-network-drives = {
    enable = true;
    config = {
      Program = "${mountScriptLauncher}";
      RunAtLoad = true;
      StartInterval = 60;
      KeepAlive = {
        NetworkState = true;
      };
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/gooskens-network-drives.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/gooskens-network-drives.err.log";
    };
  };
}
