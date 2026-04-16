# fff-mcp - MCP server for fast file search with frecency memory
# From https://github.com/dmtrKovalenko/fff.nvim
# Pre-built static musl binary from GitHub releases
{
  lib,
  fetchurl,
  autoPatchelfHook,
  stdenv,
}: let
  version = "64861f8";
in
  stdenv.mkDerivation {
    pname = "fff-mcp";
    inherit version;

    src = fetchurl {
      url = "https://github.com/dmtrKovalenko/fff.nvim/releases/download/${version}/fff-mcp-x86_64-unknown-linux-musl";
      hash = "sha256-658+Kzr7ybMlD9DtztC0JkhJ6AIM9CpZEZBQJnSzoG8=";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/fff-mcp
      chmod +x $out/bin/fff-mcp
    '';

    meta = {
      description = "MCP server for fast file search with frecency memory";
      homepage = "https://github.com/dmtrKovalenko/fff.nvim";
      license = lib.licenses.mit;
      platforms = ["x86_64-linux"];
    };
  }
