# User programs configuration - git, editors, etc.
{ pkgs, ... }: {
  # Git
  programs.git = {
    enable = true;
    settings = {
      user.name = "refactor-gremlin";
      user.email = "refactor-gremlin@users.noreply.github.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;

      # GPG signing for commits
      # TODO: Enable GPG signing by uncommenting the following lines
      # To enable:
      # 1. Create a GPG key: gpg --full-generate-key (or use existing key)
      # 2. Get your key ID: gpg --list-secret-keys --keyid-format LONG
      # 3. Uncomment and set the signingkey below with your key ID
      # 4. Add the public key to GitHub: https://github.com/settings/gpg/new
      # commit.gpgsign = true;
      # user.signingkey = "YOUR_KEY_ID";  # Format: Use the key ID (last 16 chars of the long format)
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

  # SSH
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;  # Avoid deprecated defaults
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
        addKeysToAgent = "yes";  # Automatically add keys to SSH agent
      };
    };
  };
}

