{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      # Development Tools
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

      # System Tools & Utilities
      killall # kill processes by name
      wget # non-interactive network downloader
      ghq # manage remote repository clones
      fd # simple, fast alternative to find
      tre-command # tree command, improved
      xsel # command line interface to X selections
      nvd # nixos version diff
      stow # symlink manager
      inotify-tools # Watch for file changes
      lxqt.lxqt-policykit # Authentication agent

      # Monitoring & System Info
      iftop # network monitoring
      iotop # io monitoring
      neofetch # system information tool
      lm_sensors

      # Archive Management
      p7zip # 7z file archiver
      unzip # extract ZIP archives
      zip # create ZIP archives

      # Wayland Desktop Environment
      waybar # status bar
      wofi # application launcher
      dunst # notification daemon
      swaylock-effects # screen locker
      wl-clipboard # clipboard manager
      grim # screenshot utility
      slurp # screen area selector
      hyprpicker # color picker
      hyprshot # screenshot tool
      dolphin # file manager
      pavucontrol # audio control
      playerctl # media player control
      bibata-cursors # cursor theme
      hyprcursor

      # Internet & Communication
      firefox
      google-chrome
      discord
      telegram-desktop
      zoom-us
      filezilla # ftp client

      # Media & Entertainment
      spotify
      kmplayer
      ardour

      # Productivity & Office
      bitwarden # password manager
      kcalc
      obsidian # note taking
      parsec-bin
      kemai
      # libreoffice

      # Gaming
      gamemode
      mangohud
      steamtinkerlaunch
      wine
      winetricks
      lutris

      # Creative & Design
      bambu-studio

      # Security & Privacy
      ledger-live-desktop
      # mullvad-vpn

      # Fun & Miscellaneous
      cowsay # configurable talking cow
      (fortune.override {withOffensive = true;}) # random adages
      lolcat # rainbow text

      # Backup & Disk Management
      vorta
      gparted # partition editor
    ];
  };
}
