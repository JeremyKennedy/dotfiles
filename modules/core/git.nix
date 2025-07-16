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

  # Version control packages are now in packages.nix

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
