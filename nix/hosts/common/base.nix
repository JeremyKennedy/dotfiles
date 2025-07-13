{ config, pkgs, ... }: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = ["root"];
  };
  
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  
  # Clean /tmp on boot
  boot.cleanTmpDir = true;
  
  # Set root password for console access (KVM)
  # Using initialHashedPassword - sets password on first boot only
  users.users.root.initialHashedPassword = "$y$j9T$3KdaDnlEVteVKGJVOb.7K.$dZ6nvJLslJLLOthX5ClorJgVZ2chzVq5M2fNun1QVm0"; # "nixos"
  
  # Core system packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    vim
    curl
    wget
    jq
    
    # File management
    nnn            # file manager
    broot          # tree navigator
    stow           # symlink manager
    inotify-tools  # watch for file changes
    # Archive management
    p7zip          # 7z file archiver
    unzip          # extract ZIP archives  
    zip            # create ZIP archives
    
    # System monitoring
    btop           # system monitoring
    iftop          # network monitoring
    iotop          # io monitoring  
    lm_sensors     # hardware sensors
    neofetch       # system information
    lsof           # list open files
  ];
}