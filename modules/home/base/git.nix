{...}: {
  programs.git = {
    enable = true;
    settings = {
      credential = {
        helper = [
          ""
          "/usr/local/bin/git-credential-manager"
        ];
        useHttpPath = true;
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

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
}
