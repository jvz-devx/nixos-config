# User programs configuration - git, editors, etc.
# Shared programs module for all users
# Note: User-specific settings like git name/email should be set in the user's home.nix
{ pkgs, ... }: {
  # Git (basic config, user details should be set per-user)
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  # Delta for better diffs
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
    };
  };

  # GPG
  programs.gpg.enable = true;

  # SSH (basic config, specific hosts should be added per-user)
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };
}


