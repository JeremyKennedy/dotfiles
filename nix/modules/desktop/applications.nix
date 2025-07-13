# Desktop applications
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Browsers
    firefox
    google-chrome
    
    # Communication
    discord
    telegram-desktop
    zoom-us
    
    # Productivity & Office
    bitwarden # password manager
    obsidian # note taking
    kdePackages.kcalc # calculator
    
    # Media & Entertainment
    spotify
    kmplayer
    ardour # audio workstation
    
    # File management
    filezilla # ftp client
    
    # Creative & Design
    bambu-studio
    orca-slicer
    
    # Security & Privacy
    ledger-live-desktop
  ];
}