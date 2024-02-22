{
  config,
  pkgs,
  ...
}: {
  home = {
    username = "jeremy";
    homeDirectory = "/home/jeremy";

    # This value determines the home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update home Manager without changing this value. See
    # the home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "23.11";

    packages = with pkgs; [
      # development
      alejandra # nix formatter
      any-nix-shell # nix shell manager for fish
      cht-sh # command cheatsheet
      glow # markdown previewer in terminal
      jetbrains-toolbox # jetbrains ide manager
      jetbrains.datagrip
      jetbrains.webstorm
      smartgithg # git client
      vscode # code editor

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

      # productivity
      bitwarden # password manager
      filezilla # ftp client
      firefox
      kate # text editor
      kcalc
      obsidian # note taking
      parsec-bin

      # media
      spotify

      # chat
      discord
      telegram-desktop

      # gaming
      gamemode
      steamtinkerlaunch
      winetricks

      # design
      unstable.bambu-studio
    ];
  };

  programs = {
    git = {
      enable = true;
      userName = "Jeremy Kennedy";
      userEmail = "me@jeremyk.net";
    };

    starship = {
      enable = true;
      settings = {
      };
    };

    fish = {
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

    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
    };

    eza = {
      enable = true;
      enableAliases = true;
    };

    ripgrep.enable = true;
    fzf.enable = true;
    btop.enable = true;
    tmux.enable = true;
    nnn.enable = true;
    direnv.enable = true;
    gh.enable = true;
    home-manager.enable = true;
    
    # programs to consider
    # firefox vscode
  };

  services = {
    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };
  };

  # Let home Manager install and manage itself.
}
