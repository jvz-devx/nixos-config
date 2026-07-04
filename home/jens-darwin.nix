# Home Manager configuration for jens on macOS.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  hasDotnet10 = pkgs ? dotnet-sdk_10;
  terraformDarwinArm64 = pkgs.stdenvNoCC.mkDerivation {
    pname = "terraform";
    version = "1.14.8";

    src = pkgs.fetchurl {
      url = "https://releases.hashicorp.com/terraform/1.14.8/terraform_1.14.8_darwin_arm64.zip";
      hash = "sha256-VZNnCi1CMjhHv7IW2xfHOkTfIBpi91h5KLrhat6ruiM=";
    };

    nativeBuildInputs = [pkgs.unzip];
    unpackPhase = "unzip $src";
    installPhase = ''
      install -Dm755 terraform $out/bin/terraform
    '';

    meta = {
      mainProgram = "terraform";
      platforms = ["aarch64-darwin"];
    };
  };
  gooskensAdPowerShellConfigPath = "${config.xdg.configHome}/sops-nix/secrets/rendered/gooskens-ad-ps";
  gooskensAdPowerShell = pkgs.writeShellApplication {
    name = "gooskens-ad-ps";
    runtimeInputs = [
      (pkgs.python3.withPackages (pythonPackages: [
        pythonPackages.pywinrm
      ]))
    ];
    text = ''
      set -euo pipefail

      if [ "$#" -eq 0 ]; then
        cat >&2 <<'USAGE'
      Usage:
        gooskens-ad-ps '<powershell script>'
        gooskens-ad-ps --file ./script.ps1

      Uses the macOS Keychain item:
        configured through sops-nix

      Note:
        Scripts are sent through WinRM as remote PowerShell commands.
        Large scripts can hit the Windows command-line limit; split those
        investigations into smaller focused queries.
      USAGE
        exit 2
      fi

      python - "$@" <<'PY'
      import subprocess
      import sys

      import winrm

      CONFIG_PATH = "${gooskensAdPowerShellConfigPath}"

      config = {}
      try:
          with open(CONFIG_PATH, encoding="utf-8") as config_file:
              for line in config_file:
                  line = line.strip()
                  if not line or line.startswith("#"):
                      continue
                  key, separator, value = line.partition("=")
                  if not separator:
                      continue
                  config[key.strip()] = value.strip()
      except FileNotFoundError:
          print(
              f"Missing decrypted gooskens-ad-ps config: {CONFIG_PATH}. "
              "Run darwin-rebuild switch so sops-nix can render it.",
              file=sys.stderr,
          )
          sys.exit(2)

      missing_keys = [key for key in ("server", "service", "account") if not config.get(key)]
      if missing_keys:
          print(
              f"Missing key(s) in {CONFIG_PATH}: {', '.join(missing_keys)}",
              file=sys.stderr,
          )
          sys.exit(2)

      SERVER = config["server"]
      SERVICE = config["service"]
      ACCOUNT = config["account"]

      args = sys.argv[1:]
      if args[0] in ("-f", "--file"):
          if len(args) != 2:
              print("Usage: gooskens-ad-ps --file ./script.ps1", file=sys.stderr)
              sys.exit(2)
          with open(args[1], encoding="utf-8") as script_file:
              script = script_file.read()
      else:
          script = " ".join(args)

      if not script.strip():
          print("No PowerShell script was provided.", file=sys.stderr)
          sys.exit(2)

      max_script_chars = 7000
      if len(script) > max_script_chars:
          print(
              f"PowerShell script is {len(script)} characters, which is likely too long for this WinRM transport. "
              "Split it into smaller focused queries instead of using one large --file script.",
              file=sys.stderr,
          )
          sys.exit(2)

      password = subprocess.check_output(
          [
              "/usr/bin/security",
              "find-generic-password",
              "-w",
              "-s",
              SERVICE,
              "-a",
              ACCOUNT,
          ],
          text=True,
      ).rstrip("\n")

      try:
          session = winrm.Session(
              f"http://{SERVER}:5985/wsman",
              auth=(ACCOUNT, password),
              transport="ntlm",
          )
          result = session.run_ps("$ProgressPreference = 'SilentlyContinue'\n" + script)
      finally:
          password = None

      stdout = result.std_out.decode("utf-8", errors="replace")
      stderr = result.std_err.decode("utf-8", errors="replace")

      if stdout:
          print(stdout, end="")
      if stderr:
          print(stderr, end="", file=sys.stderr)

      sys.exit(result.status_code)
      PY
    '';
  };
in {
  imports = [
    ../modules/home/base/git.nix
    ../modules/home/base/ssh.nix
    ../modules/home/base/tmux.nix
    ../modules/home/base/gpg.nix
    ../modules/home/packages/cli/base.nix
    ../modules/home/features/gooskens-network-drives-darwin.nix
  ];

  home = {
    username = "jens";
    homeDirectory = "/Users/jens";
    stateVersion = "26.05";

    sessionPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
      "/opt/homebrew/opt/rustup/bin"
      "$HOME/.local/bin"
      "$HOME/.npm-global/bin"
      "$HOME/.nvm/versions/node/bin"
    ];

    sessionVariables = {
      EDITOR = "nano";
      VISUAL = "nano";
      NVM_DIR = "$HOME/.nvm";
    };

    packages =
      (with pkgs; [
        gh
        powershell
        gooskensAdPowerShell
        jq
        yq-go
        ripgrep
        fd
        eza
        bat
        go
        bun
        deno
        pnpm
        terraformDarwinArm64
        kubectl
        k9s
        fluxcd
        ansible
        cf
        inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      ])
      ++ lib.optionals hasDotnet10 [
        pkgs.dotnet-sdk_10
      ];
  };

  programs.home-manager.enable = true;

  sops = {
    secrets = {
      gooskens_ad_ps_server = {};
      gooskens_ad_ps_service = {};
      gooskens_ad_ps_account = {};
    };

    templates."gooskens-ad-ps" = {
      path = gooskensAdPowerShellConfigPath;
      mode = "0600";
      content = ''
        server=${config.sops.placeholder.gooskens_ad_ps_server}
        service=${config.sops.placeholder.gooskens_ad_ps_service}
        account=${config.sops.placeholder.gooskens_ad_ps_account}
      '';
    };
  };

  home.activation.setCodexFullAccessDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
    set -eu

    codex_config="${config.home.homeDirectory}/.codex/config.toml"
    ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$codex_config")"

    if [ ! -e "$codex_config" ]; then
      ${pkgs.coreutils}/bin/install -m 600 /dev/null "$codex_config"
    fi

    ${pkgs.perl}/bin/perl -0pi -e 's/^approval_policy\s*=.*$/approval_policy = "never"/m or s/\A/approval_policy = "never"\n/' "$codex_config"
    ${pkgs.perl}/bin/perl -0pi -e 's/^sandbox_mode\s*=.*$/sandbox_mode = "danger-full-access"/m or s/\A/sandbox_mode = "danger-full-access"\n/' "$codex_config"
    ${pkgs.coreutils}/bin/chmod 600 "$codex_config"
  '';

  home.activation.configureCodexFffMcp = lib.hm.dag.entryAfter ["setCodexFullAccessDefaults"] ''
    set -eu

    codex_config="${config.home.homeDirectory}/.codex/config.toml"
    tmp="$(${pkgs.coreutils}/bin/mktemp)"

    ${pkgs.gawk}/bin/awk '
      BEGIN {
        in_fff = 0
        wrote = 0
      }
      /^\[mcp_servers\.fff\]$/ {
        if (!wrote) {
          print "[mcp_servers.fff]"
          print "command = \"/opt/homebrew/bin/fff-mcp\""
          print "args = []"
          wrote = 1
        }
        in_fff = 1
        next
      }
      /^\[/ {
        in_fff = 0
      }
      !in_fff {
        print
      }
      END {
        if (!wrote) {
          print ""
          print "[mcp_servers.fff]"
          print "command = \"/opt/homebrew/bin/fff-mcp\""
          print "args = []"
        }
      }
    ' "$codex_config" > "$tmp"

    ${pkgs.coreutils}/bin/cat "$tmp" > "$codex_config"
    ${pkgs.coreutils}/bin/rm -f "$tmp"
    ${pkgs.coreutils}/bin/chmod 600 "$codex_config"
  '';

  home.file.".codex/skills/fff/SKILL.md".source = ../modules/home/codex-skills/fff/SKILL.md;

  home.file.".docker/cli-plugins/docker-compose" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/docker-compose";
    executable = true;
  };

  home.file.".hammerspoon/init.lua".text = ''
    hs.window.animationDuration = 0
    hs.ipc.cliInstall()
    hs.allowAppleScript(true)

    local logFile = io.open(os.getenv("HOME") .. "/.hammerspoon/window-snap.log", "a")
    if logFile then
      logFile:write(os.date("%Y-%m-%d %H:%M:%S") .. " loading window snapping\n")
      logFile:close()
    end

    local hyper = { "ctrl", "alt", "cmd", "shift" }
    local savedFrames = {}
    local widths = { 0.5, 2 / 3, 1 / 3 }
    local tolerance = 14

    local function focusedWindow()
      return hs.window.focusedWindow()
    end

    local function visibleFrame(win)
      return win:screen():frame()
    end

    local function close(a, b)
      return math.abs(a - b) <= tolerance
    end

    local function frameEquals(frame, target)
      return close(frame.x, target.x)
        and close(frame.y, target.y)
        and close(frame.w, target.w)
        and close(frame.h, target.h)
    end

    local function rect(screen, x, y, w, h)
      return {
        x = screen.x + screen.w * x,
        y = screen.y + screen.h * y,
        w = screen.w * w,
        h = screen.h * h,
      }
    end

    local function state(win)
      local screen = visibleFrame(win)
      local frame = win:frame()
      local states = {
        maximized = rect(screen, 0, 0, 1, 1),
        left = rect(screen, 0, 0, 0.5, 1),
        right = rect(screen, 0.5, 0, 0.5, 1),
        top = rect(screen, 0, 0, 1, 0.5),
        bottom = rect(screen, 0, 0.5, 1, 0.5),
        topLeft = rect(screen, 0, 0, 0.5, 0.5),
        topRight = rect(screen, 0.5, 0, 0.5, 0.5),
        bottomLeft = rect(screen, 0, 0.5, 0.5, 0.5),
        bottomRight = rect(screen, 0.5, 0.5, 0.5, 0.5),
      }

      for name, target in pairs(states) do
        if frameEquals(frame, target) then
          return name
        end
      end

      return "floating"
    end

    local function setFrame(win, target)
      win:setFrame(target, 0)
    end

    local function remember(win)
      if state(win) ~= "maximized" then
        savedFrames[win:id()] = win:frame()
      end
    end

    local function restore(win)
      local previous = savedFrames[win:id()]
      if previous then
        setFrame(win, previous)
        return
      end

      local screen = visibleFrame(win)
      setFrame(win, rect(screen, 0.15, 0.12, 0.7, 0.76))
    end

    local function side(win, direction)
      local screen = visibleFrame(win)
      local frame = win:frame()
      local currentWidth = frame.w / screen.w
      local nextWidth = widths[1]

      local onRequestedSide =
        (direction == "left" and close(frame.x, screen.x))
        or (direction == "right" and close(frame.x + frame.w, screen.x + screen.w))

      if onRequestedSide then
        for index, width in ipairs(widths) do
          if math.abs(currentWidth - width) < 0.04 then
            nextWidth = widths[(index % #widths) + 1]
            break
          end
        end
      end

      if direction == "left" then
        setFrame(win, rect(screen, 0, 0, nextWidth, 1))
      else
        setFrame(win, rect(screen, 1 - nextWidth, 0, nextWidth, 1))
      end
    end

    local function snapUp()
      local win = focusedWindow()
      if not win then return end

      local screen = visibleFrame(win)
      local current = state(win)

      if current == "left" then
        setFrame(win, rect(screen, 0, 0, 0.5, 0.5))
      elseif current == "right" then
        setFrame(win, rect(screen, 0.5, 0, 0.5, 0.5))
      elseif current == "bottomLeft" then
        setFrame(win, rect(screen, 0, 0, 0.5, 1))
      elseif current == "bottomRight" then
        setFrame(win, rect(screen, 0.5, 0, 0.5, 1))
      elseif current == "bottom" then
        remember(win)
        setFrame(win, rect(screen, 0, 0, 1, 1))
      else
        remember(win)
        setFrame(win, rect(screen, 0, 0, 1, 1))
      end
    end

    local function snapDown()
      local win = focusedWindow()
      if not win then return end

      local screen = visibleFrame(win)
      local current = state(win)

      if current == "maximized" then
        restore(win)
      elseif current == "left" then
        setFrame(win, rect(screen, 0, 0.5, 0.5, 0.5))
      elseif current == "right" then
        setFrame(win, rect(screen, 0.5, 0.5, 0.5, 0.5))
      elseif current == "topLeft" then
        setFrame(win, rect(screen, 0, 0, 0.5, 1))
      elseif current == "topRight" then
        setFrame(win, rect(screen, 0.5, 0, 0.5, 1))
      elseif current == "top" then
        restore(win)
      else
        setFrame(win, rect(screen, 0, 0.5, 1, 0.5))
      end
    end

    hs.hotkey.bind(hyper, "left", function()
      local win = focusedWindow()
      if win then side(win, "left") end
    end)

    hs.hotkey.bind(hyper, "right", function()
      local win = focusedWindow()
      if win then side(win, "right") end
    end)

    hs.hotkey.bind(hyper, "up", snapUp)
    hs.hotkey.bind(hyper, "down", snapDown)

    hs.hotkey.bind(hyper, "s", function()
      hs.task.new("/usr/sbin/screencapture", nil, { "-i", "-c" }):start()
    end)

    hs.hotkey.bind({ "ctrl", "shift" }, "escape", function()
      hs.application.launchOrFocus("Activity Monitor")
    end)

    hs.alert.show("Hammerspoon window snapping loaded")
  '';

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        "git"
        "docker"
        "npm"
        "fzf"
        "zoxide"
        "direnv"
      ];
    };

    shellAliases = {
      ll = "eza -la";
      cat = "bat";
      grep = "rg";
      rebuild = "sudo darwin-rebuild switch --flake ~/nix#macbook-pro";
      rebuild-mac = "sudo darwin-rebuild switch --flake ~/nix#macbook-pro";
      update = "cd ~/nix && nix flake update && sudo darwin-rebuild switch --flake .#macbook-pro";
      update-mac = "cd ~/nix && nix flake update && sudo darwin-rebuild switch --flake .#macbook-pro";
    };

    initContent = ''
      if [[ -d /opt/homebrew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      fi

      if [[ -s /opt/homebrew/opt/nvm/nvm.sh ]]; then
        mkdir -p "$NVM_DIR"
        . /opt/homebrew/opt/nvm/nvm.sh
      fi
    '';
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.git.settings = {
    user.name = "jvz-devx";
    user.email = "jvz-devx@users.noreply.github.com";
    init.defaultBranch = "main";
    pull.rebase = lib.mkForce false;
  };

  programs.ssh.matchBlocks = {
    "github.com" = {
      hostname = "github.com";
      user = "git";
      identityFile = "~/.ssh/id_ed25519";
      identitiesOnly = true;
      addKeysToAgent = "yes";
    };
  };
}
