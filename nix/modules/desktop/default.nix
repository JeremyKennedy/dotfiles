# Desktop modules - imported by desktop profile
# These are desktop/GUI specific modules that servers don't need
{...}: {
  imports = [
    ./graphics.nix # AMD GPU configuration
    ./hyprland.nix # Hyprland window manager
    ./waybar.nix # Waybar status bar
    ./ledger.nix # Hardware wallet support
    ./programs.nix # Desktop programs (Steam, ADB, KDEConnect)
    ./wayland.nix # Wayland environment configuration
    ./services.nix # Desktop services (printing, avahi, docker, etc)
    ./gaming.nix # Gaming and streaming (GameMode, Sunshine)
    ./fonts.nix # Desktop fonts
    ./users.nix # Desktop user configuration
  ];
}
