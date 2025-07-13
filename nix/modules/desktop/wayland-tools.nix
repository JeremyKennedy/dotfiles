# Wayland desktop utilities (not Hyprland-specific)
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # Wayland utilities
    waybar # status bar
    wofi # application launcher
    dunst # notification daemon
    
    # Clipboard management
    wl-clipboard # clipboard manager
    wl-clip-persist # clipboard manager
    cliphist # clipboard manager
    
    # Audio/Media control
    pavucontrol # audio control
    playerctl # media player control
    
    # Theming
    bibata-cursors # cursor theme
    
    # System utilities
    libnotify # Desktop notifications (provides notify-send)
    lxqt.lxqt-policykit # Authentication agent
  ];
}