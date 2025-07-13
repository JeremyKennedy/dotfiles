{pkgs, ...}: {
  programs.git = {
    enable = true;
    config = {
      user.name = "Jeremy Kennedy";
      user.email = "me@jeremyk.net";
      init.defaultBranch = "main";
      core.editor = "nvim";
      diff.tool = "delta";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.enable = true;
    };
  };

  # Version control tools
  environment.systemPackages = with pkgs; [
    jujutsu
    delta # syntax-highlighting pager for git
    gh # GitHub CLI
    ghq # manage remote repository clones
  ];

  # Jujutsu configuration
  environment.etc."jj/config.toml".text = ''
    [user]
    name = "Jeremy Kennedy"
    email = "me@jeremyk.net"

    [ui]
    default-command = "log"
    editor = "nvim"
  '';
}
