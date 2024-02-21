{
  config,
  pkgs,
  ...
}: {
  home.username = "jeremy";
  home.homeDirectory = "/home/jeremy";

  # link the configuration file in current directory to the specified location in home directory
  # home.file.".config/i3/wallpaper.jpg".source = ./wallpaper.jpg;

  # link all files in `./scripts` to `~/.config/i3/scripts`
  # home.file.".config/i3/scripts" = {
  #   source = ./scripts;
  #   recursive = true;   # link recursively
  #   executable = true;  # make all files executable
  # };

  # encode the file content in nix configuration file directly
  # home.file.".xxx".text = ''
  #     xxx
  # '';

  # set cursor size and dpi for 4k monitor
  # xresources.properties = {
  #   "Xcursor.size" = 16;
  #   "Xft.dpi" = 172;
  # };

  home.packages = with pkgs; [
    # code
    alejandra
    any-nix-shell
    cht-sh
    direnv
    gh
    glow # markdown previewer in terminal

    # utils
    busybox
    fzf # A command-line fuzzy finder
    nnn # terminal file manager
    ripgrep # recursively searches directories for a regex pattern
    tmux
    wget
    ghq # manage remote repository clones

    # archives
    p7zip
    unzip
    zip

    # monitoring
    btop # replacement of htop/nmon
    iftop # network monitoring
    iotop # io monitoring

    # misc
    cowsay
    fortune
    lolcat
    neofetch

    # programs
    gparted
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
        fortune | cowsay -n | lolcat
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

  # alacritty - a cross-platform, GPU-accelerated terminal emulator
  # programs.alacritty = {
  #   enable = true;
  #   # custom settings
  #   settings = {
  #     env.TERM = "xterm-256color";
  #     font = {
  #       size = 12;
  #       draw_bold_text_with_bright_colors = true;
  #     };
  #     scrolling.multiplier = 5;
  #     selection.save_to_clipboard = true;
  #   };
  # };

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
