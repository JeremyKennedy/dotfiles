# Wayland/Hyprland environment configuration
{...}: {
  # Wayland environment variables for all applications
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Enable Wayland for Electron apps
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix cursor rendering issues
    XDG_SESSION_TYPE = "wayland";
    WAYLAND_DISPLAY = "wayland-1";
    QT_QPA_PLATFORM = "wayland";
    GDK_BACKEND = "wayland";
  };

  # Disable X11 since we're using Wayland
  services.xserver.enable = false;
}
