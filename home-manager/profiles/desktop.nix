# Desktop home-manager profile
# Includes base + desktop-specific configurations
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./base.nix
    ../modules/shell/desktop.nix  # Desktop-specific shell functions
    ../modules/terminal.nix  # Terminal emulator configuration
  ];

  # Desktop-specific packages
  home.packages = with pkgs; [
    # X11/Wayland utilities
    xsel # clipboard

    # System monitoring
    radeontop # AMD GPU monitoring
    nvd # nixos version diff

    # Graphics
    libva
    libva-utils
    vulkan-tools

    # Media
    sox # play command
    sound-theme-freedesktop

    # GUI applications
    nextcloud-client
    kemai
    gparted
    vorta

    # Fun extras
    lolcat # rainbow text

    # Disk management
    udiskie # automount
  ];

  # Desktop-specific programs
  programs = {
    # Shell configuration moved to modules/shell/desktop.nix
    # Terminal configuration moved to modules/terminal.nix
  };

  # Desktop services
  services = {
    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };

    # Wayland idle management
    hypridle = {
      enable = true;
    };

    # Desktop notifications
    dunst = {
      enable = true;
      settings = {
        global = {
          origin = "top-right";
          monitor = 1;
          font = "JetBrainsMono Nerd Font 12";
        };
      };
    };
  };

  # Desktop-specific pointer cursor
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  # XDG configuration files
  xdg.configFile = {
    "hypr/hyprland.conf".source = ../../modules/desktop/hyprland/configs/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = ../../modules/desktop/hyprland/configs/hypr/hypridle.conf;
    "hypr/hyprlock.conf".source = ../../modules/desktop/hyprland/configs/hypr/hyprlock.conf;
    "waybar/config".source = ../../modules/desktop/hyprland/configs/waybar/config;
    "waybar/style.css".source = ../../modules/desktop/hyprland/configs/waybar/style.css;
    "wofi/config".source = ../../modules/desktop/hyprland/configs/wofi/config;
    "wofi/style.css".source = ../../modules/desktop/hyprland/configs/wofi/style.css;
  };
}
