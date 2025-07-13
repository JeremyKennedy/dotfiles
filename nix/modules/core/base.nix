{
  config,
  pkgs,
  inputs,
  ...
}: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = ["root"];
  };

  # Automatic garbage collection and optimization
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Automatic store optimization (deduplication)
  nix.optimise = {
    automatic = true;
    dates = ["weekly"];
  };

  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set root password for console access (KVM)
  # Using initialHashedPassword - sets password on first boot only
  users.users.root.initialHashedPassword = "$y$j9T$7tHof6eMlrWk9qrOIjM3m1$Tpfd5r.xgKuSxdFlvDWqJv39gGyS0ceiJt8OSYde1N6"; # "nixos"

  # Core system packages
  environment.systemPackages = with pkgs; [
    # Development tools
    claude-code # AI-powered code assistant

    # Basic utilities
    vim
    curl
    wget
    jq

    # Secrets management
    # agenix is available through the overlay

    # Network diagnostic tools
    dig
    bind # includes nslookup

    # File management
    nnn # file manager
    broot # tree navigator
    stow # symlink manager
    inotify-tools # watch for file changes
    # Archive management
    p7zip # 7z file archiver
    unzip # extract ZIP archives
    zip # create ZIP archives

    # System monitoring
    btop # system monitoring
    iftop # network monitoring
    iotop # io monitoring
    lm_sensors # hardware sensors
    neofetch # system information
    lsof # list open files
  ];
}
