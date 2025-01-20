{
  config,
  pkgs,
  ...
}: {
  home = {
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
      code-cursor
      git-crypt # transparent file encryption in git

      # utils
      killall # kill processes by name
      wget # non-interactive network downloader
      ghq # manage remote repository clones
      fd # simple, fast and user-friendly alternative to find
      tre-command # tree command, improved
      xsel # command line interface to X selections
      nvd # nixos version diff

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
      vorta

      # productivity
      bitwarden # password manager
      filezilla # ftp client
      firefox
      google-chrome
      kcalc
      obsidian # note taking
      parsec-bin
      kemai
      # libreoffice

      # media
      spotify
      kmplayer
      ardour

      # chat
      discord
      telegram-desktop
      zoom-us

      # gaming
      gamemode
      mangohud
      steamtinkerlaunch
      wine
      winetricks
      lutris

      # design
      bambu-studio

      # crypto
      ledger-live-desktop
      # mullvad-vpn

      # Wayland utilities
      waybar
      wofi
      dunst
      swaylock-effects
      wl-clipboard
      grim
      slurp
      hyprpicker
      lm_sensors
      dolphin
      pavucontrol
      playerctl

      # System utilities
      stow # symlink manager
      lxqt.lxqt-policykit # Authentication agent
      inotify-tools # Watch for file changes

      # Cursor themes
      bibata-cursors
      hyprcursor
    ];
  };
}
