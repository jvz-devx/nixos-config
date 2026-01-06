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
        sha256 = "sha256-k6FDa5tBEHIEtVm6JTSOMylN89IMoZYZ4MLF/NIaKNA=";
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
      ];
    runScript = "${coderabbit-binary}/bin/coderabbit";

    # FIX: The FHS environment is a sandbox that doesn't inherit the host filesystem by default.
    # To allow CodeRabbit to work in arbitrary directories (like /etc/nixos or /home/user),
    # we need to explicitly bind mount them.
    #
    # 1. Create the mount points inside the FHS environment first
    extraBuildCommands = ''
      mkdir -p $out/etc/nixos
    '';

    # 2. Bind mount the host directories to those mount points
    # We bind /home for user projects and /etc/nixos for system config access
    extraBindMounts = [
      {
        source = "/home";
        target = "/home";
      }
      {
        source = "/etc/nixos";
        target = "/etc/nixos";
      }
    ];
  };

  # Create wrapper script that invokes the FHS environment
  coderabbit-wrapper = pkgs.writeShellScriptBin "coderabbit" ''
    exec ${coderabbit-fhs}/bin/coderabbit-fhs "$@"
  '';

  # Create 'cr' wrapper
  cr-wrapper = pkgs.writeShellScriptBin "cr" ''
    exec ${coderabbit-fhs}/bin/coderabbit-fhs "$@"
  '';
in
  # Return a combined package with both wrappers
  pkgs.symlinkJoin {
    name = "coderabbit-${version}";
    paths = [coderabbit-wrapper cr-wrapper];
    meta = with lib; {
      description = "CodeRabbit CLI - AI-powered code review tool";
      homepage = "https://docs.coderabbit.ai/cli";
      license = licenses.unfree;
      platforms = ["x86_64-linux"];
      maintainers = [];
    };
  }
