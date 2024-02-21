{
  config,
  pkgs,
  ...
}: {
  home.username = "jeremy";
  home.homeDirectory = "/home/jeremy";

  home.packages = with pkgs; [
    # code
    alejandra # nix formatter
    any-nix-shell # nix shell manager for fish
    cht-sh # cheat.sh
    glow # markdown previewer in terminal

    # utils
    busybox # swiss army knife of embedded Linux
    wget # non-interactive network downloader
    ghq # manage remote repository clones

    # archives
    p7zip # 7z file archiver with high compression ratio
    unzip # list, test and extract compressed files in a ZIP archive
    zip # package and compress archive files

    # monitoring
    iftop # network monitoring
    iotop # io monitoring

    # misc
    cowsay # configurable talking cow
    (fortune.override {withOffensive = true;}) # print a random, hopefully interesting, adage
    lolcat # rainbowify your terminal
    neofetch # system information tool

    # programs
    gparted # partition editor for graphically managing your disk partitions
  ];

  programs.git = {
    enable = true;
    userName = "Jeremy Kennedy";
    userEmail = "me@jeremyk.net";
  };

  programs.starship = {
    enable = true;
    settings = {
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      any-nix-shell fish --info-right | source

      function fish_greeting
        fortune -a | cowsay -n | lolcat
      end
    '';
    shellAbbrs = {
      gh = "ghq";
      g = "git";
      v = "nvim";
      e = "eza";
    };
    plugins = [
      {
        name = "z";
        src = pkgs.fishPlugins.z.src;
      }
    ];
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  programs.eza = {
    enable = true;
    enableAliases = true;
  };

  programs.ripgrep = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
  };

  programs.btop = {
    enable = true;
  };

  programs.tmux = {
    enable = true;
  };

  programs.nnn = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
  };

  programs.gh = {
    enable = true;
  };

  services.nextcloud-client = {
    enable = true;
    startInBackground = true;
  };

  # programs to consider
  # firefox vscode

  # This value determines the home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update home Manager without changing this value. See
  # the home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";

  # Let home Manager install and manage itself.
  programs.home-manager.enable = true;
}
