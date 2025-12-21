# CodeRabbit CLI package - DISABLED (see comments below)
# 
# This package is currently disabled because the CodeRabbit binary (which is Bun-based)
# cannot be properly packaged for NixOS. The binary checks its execution context to
# determine whether to run as CodeRabbit CLI or as generic Bun runtime, and after
# Nix patching it always runs as Bun instead of CodeRabbit.
#
# Approaches tried:
# 1. Manual patchelf:
#    - Result: "unsupported version 0 of Verdef record" errors and segfaults
#    - Reason: Binary has complex ELF structures that manual patchelf can't handle
#
# 2. autoPatchelfHook:
#    - Result: Binary patches successfully without crashes, but always shows Bun help
#    - Tried exec -a "coderabbit" wrapper to set argv[0] - didn't work
#    - Tried symlinks - didn't work  
#    - Tried preserving binary name - didn't work
#    - The binary appears to check something other than argv[0] (possibly /proc/self/exe,
#      embedded resources, environment variables, or file checksums)
#
# 3. Testing showed:
#    - Fresh binary from zip works correctly (shows CodeRabbit help)
#    - After Nix patching, binary loses ability to detect it should run as CodeRabbit
#    - Binary works when run directly but not when patched for NixOS
#
# Possible future solutions:
# - Use buildFHSUserEnv to run in a more traditional Linux environment
# - Check for required environment variables
# - Investigate if embedded resources get corrupted during patching
# - Use AppImage-style wrapper approach
# - Wait for CodeRabbit to provide a proper Nix package or better binary distribution
#
# Manual installation (works fine):
#   curl -fsSL https://cli.coderabbit.ai/install.sh | bash

{ pkgs, lib, stdenv, fetchzip, unzip, autoPatchelfHook }:

# DISABLED - returning null so the package can be referenced but won't build
# Uncomment the derivation below to re-enable (but it won't work correctly)
null

/*
stdenv.mkDerivation rec {
  pname = "coderabbit";
  version = "0.3.5";  # Get latest from: curl -s https://cli.coderabbit.ai/releases/latest/VERSION

  # CodeRabbit CLI releases
  # Check https://cli.coderabbit.ai/releases/latest/VERSION for latest version
  src = fetchzip {
    url = "https://cli.coderabbit.ai/releases/${version}/coderabbit-linux-x64.zip";
    sha256 = "sha256-k6FDa5tBEHIEtVm6JTSOMylN89IMoZYZ4MLF/NIaKNA=";
    stripRoot = false;
  };

  nativeBuildInputs = [ unzip autoPatchelfHook ];
  
  # Libraries needed for the dynamically linked binary
  buildInputs = with pkgs; [
    glibc
    zlib
    openssl
    libgcc
  ];

  installPhase = ''
    mkdir -p $out/bin
    # The zip contains a single binary file named 'coderabbit'
    # Install it directly as 'coderabbit' - the binary checks its name/path
    cp coderabbit $out/bin/coderabbit
    chmod +x $out/bin/coderabbit
    
    # Create 'cr' as a symlink to coderabbit
    ln -s coderabbit $out/bin/cr
  '';
  
  # autoPatchelfHook will automatically patch the binary during fixup phase
  # This handles complex ELF structures better than manual patchelf

  meta = with lib; {
    description = "CodeRabbit CLI - AI-powered code review tool";
    homepage = "https://docs.coderabbit.ai/cli";
    license = licenses.unfree;  # Check actual license
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
  };
}
*/

