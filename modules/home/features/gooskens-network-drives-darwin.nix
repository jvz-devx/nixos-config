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

        mount_share() {
          local mount_name="$1"
          local url="$2"
          local mount_point="/Volumes/$mount_name"
          local mount_line

          mount_line=$(/sbin/mount | /usr/bin/grep -F " on $mount_point " || true)

          if [ -n "$mount_line" ]; then
            if printf '%s\n' "$mount_line" | /usr/bin/grep -Fq '//adminje@'; then
              return 0
            fi

            printf 'Remounting %s because it is not mounted as adminje: %s\n' "$mount_point" "$mount_line" >&2
            if ! /sbin/umount "$mount_point"; then
              printf 'Failed to unmount %s; will retry later\n' "$mount_point" >&2
              return 0
            fi
          fi

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
      StartInterval = 300;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/gooskens-network-drives.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/gooskens-network-drives.err.log";
    };
  };
}
