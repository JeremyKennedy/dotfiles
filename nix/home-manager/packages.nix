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
      vorta

      # productivity
      bitwarden # password manager
      filezilla # ftp client
      firefox
      kate # text editor
      kcalc
      obsidian # note taking
      parsec-bin
      kemai

      # media
      spotify
      kmplayer

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
}