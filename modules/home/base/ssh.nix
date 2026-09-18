{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "gitlab.com *.gitlab.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_gitlab";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        AddKeysToAgent = "yes";
      };
    };
  };
}
