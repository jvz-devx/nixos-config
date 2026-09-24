# Interactive PowerShell on Gooskens Windows servers over WinRM, plus a herdr
# plugin that opens it in a tab. Nothing gets installed on the servers.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # Same sops-rendered config (server, Keychain service/account) as gooskens-ad-ps.
  configPath = "${config.xdg.configHome}/sops-nix/secrets/rendered/gooskens-ad-ps";

  # psrpcore is marked broken on Darwin only because its test suite needs
  # PowerShell; the library itself is pure Python.
  python = pkgs.python3.override {
    packageOverrides = _: super: {
      psrpcore = super.psrpcore.overridePythonAttrs (old: {
        doCheck = false;
        meta = old.meta // {broken = false;};
      });
      pypsrp = super.pypsrp.overridePythonAttrs (_: {doCheck = false;});
    };
  };

  gooskensAdShell = pkgs.writeShellApplication {
    name = "gooskens-ad-shell";
    runtimeInputs = [(python.withPackages (p: [p.pypsrp]))];
    text = ''
      exec python ${./ad_shell.py} --config "${configPath}" \
        --password-file "${config.sops.secrets.gooskens_ad_ps_password.path}" "$@"
    '';
  };
in {
  home.packages = [gooskensAdShell];

  # Fallback for sessions that can't read the login Keychain, such as herdr
  # servers started over SSH (the Work · DC sidebar machines on localhost).
  sops.secrets.gooskens_ad_ps_password.mode = "0400";

  # herdr resolves symlinks when linking a plugin, so a Home Manager symlink
  # would pin it to a /nix/store path. Copy real files instead; linked once with
  # `herdr plugin link ~/.local/share/herdr-plugins/gooskens-windows`.
  # The server list lives in `herdr plugin config-dir gooskens.windows`/servers,
  # outside this repo.
  home.activation.gooskensWindowsHerdrPlugin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    dest="$HOME/.local/share/herdr-plugins/gooskens-windows"
    run mkdir -p "$dest"
    run install -m 644 ${./herdr-plugin}/* "$dest/"
  '';
}
