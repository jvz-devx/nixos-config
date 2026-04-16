# CodeRabbit CLI package
#
# This uses buildFHSUserEnv to run the binary in an FHS-compliant sandbox
# without patching it. The CodeRabbit binary (Bun-based) checks its execution
# context to determine whether to run as CodeRabbit CLI or as generic Bun runtime.
# Traditional Nix patchelf breaks this detection, causing it to always run as Bun.
#
# Solution: Use buildFHSUserEnv to create an environment that provides libraries
# at standard FHS paths while keeping the binary completely unmodified.
#
# Works by:
# 1. Extracting and installing the binary to a temporary location without patching
# 2. Creating an FHS sandbox environment with standard library paths
# 3. The wrapper script runs the binary inside the sandbox where it can detect
#    it should run as CodeRabbit based on its name/context
{
  pkgs,
  lib,
  runCommand,
  fetchzip,
}: let
  # Version info - check https://cli.coderabbit.ai/releases/latest/VERSION for latest
  version = "0.3.5";

  # Extract the binary without patching
  coderabbit-binary =
    runCommand "coderabbit-binary-unpatched"
    {
      pname = "coderabbit-binary";
      inherit version;
      src = fetchzip {
        url = "https://cli.coderabbit.ai/releases/${version}/coderabbit-linux-x64.zip";
        hash = "sha256-k6FDa5tBEHIEtVm6JTSOMylN89IMoZYZ4MLF/NIaKNA=";
        stripRoot = false;
      };
      dontPatchELF = true;
      dontStrip = true;
    }
    ''
      mkdir -p $out/bin
      cp $src/coderabbit $out/bin/coderabbit
      chmod +x $out/bin/coderabbit

      # Create 'cr' as a symlink to coderabbit
      ln -s coderabbit $out/bin/cr
    '';

  # FHS environment with required libraries
  coderabbit-fhs = pkgs.buildFHSEnv {
    name = "coderabbit-fhs";
    # Libraries provided at standard FHS paths (/usr/lib, /lib/x86_64-linux-gnu/)
    targetPkgs = pkgs:
      with pkgs; [
        glibc
        zlib
        openssl
        libgcc
        libsecret
        glib
        dbus
        at-spi2-core
        libgcrypt
        libgpg-error
        p11-kit
        util-linux # for libuuid
        nss
        nspr
        sqlite
        git # Added to allow CodeRabbit to detect and interact with Git repositories
      ];
    runScript = lib.getExe' coderabbit-binary "coderabbit";

    profile = ''
      export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
    '';

    # Create the mount points in the sandbox rootfs
    extraBuildCommands = ''
      mkdir -p $out/etc/nixos
      mkdir -p $out/home
      mkdir -p $out/run/user
    '';

    # Bind mount the host directories using bwrap arguments
    # Security notes:
    # - /home: MUST be read-write (--bind) because Bun/CodeRabbit writes cache files,
    #   configs, and temp data to ~/.cache, ~/.config, etc. Read-only causes EROFS errors.
    # - /etc/nixos: Read-only (--ro-bind) is sufficient for code review.
    # - /run/user: Ideally we'd bind only /run/user/$(id -u) for the current user, but
    #   extraBwrapArgs are evaluated at build time, not runtime. Binding all of /run/user
    #   is a trade-off for simplicity on single-user workstations. On multi-user systems,
    #   consider a custom wrapper that invokes bwrap directly with dynamic arguments.
    extraBwrapArgs = [
      "--bind"
      "/home"
      "/home"
      "--ro-bind"
      "/etc/nixos"
      "/etc/nixos"
      "--bind"
      "/run/user"
      "/run/user"
    ];
  };

  # Create wrapper script that invokes the FHS environment
  # Git safe.directory is set dynamically to trust only:
  # 1. The current working directory ($PWD) - the repo being reviewed
  # 2. /etc/nixos - system config (read-only mounted)
  # This is more secure than trusting all of /home.
  coderabbit-wrapper = pkgs.writeShellScriptBin "coderabbit" ''
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0=safe.directory
    export GIT_CONFIG_VALUE_0="$PWD"
    export GIT_CONFIG_KEY_1=safe.directory
    export GIT_CONFIG_VALUE_1='/etc/nixos'
    exec ${lib.getExe coderabbit-fhs} "$@"
  '';

  # Create 'cr' wrapper
  cr-wrapper = pkgs.writeShellScriptBin "cr" ''
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0=safe.directory
    export GIT_CONFIG_VALUE_0="$PWD"
    export GIT_CONFIG_KEY_1=safe.directory
    export GIT_CONFIG_VALUE_1='/etc/nixos'
    exec ${lib.getExe coderabbit-fhs} "$@"
  '';
in
  # Return a combined package with both wrappers
  pkgs.symlinkJoin {
    name = "coderabbit-${version}";
    paths = [coderabbit-wrapper cr-wrapper];
    meta = {
      description = "CodeRabbit CLI - AI-powered code review tool";
      homepage = "https://docs.coderabbit.ai/cli";
      license = lib.licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
