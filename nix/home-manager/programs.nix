{
  config,
  pkgs,
  ...
}: {
  programs = {
    git = {
      enable = true;
      userName = "Jeremy Kennedy";
      userEmail = "me@jeremyk.net";
    };

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    eza = {
      enable = true;
      enableAliases = true;
    };

    ripgrep.enable = true;
    btop.enable = true;
    tmux.enable = true;
    nnn.enable = true;
    direnv.enable = true;
    gh.enable = true;
    home-manager.enable = true;
    broot.enable = true;

    # programs to consider
    # firefox vscode
  };
}
