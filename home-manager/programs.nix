{
  config,
  pkgs,
  ...
}: {
  programs = {
    # Most programs moved to core modules
    # Keep only home-manager specific
    home-manager.enable = true;

    # programs to consider
    # firefox vscode
  };

  # Hyprland configuration files
  xdg.configFile = {
    "hypr/hyprland.conf".source = ../modules/desktop/hyprland/configs/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = ../modules/desktop/hyprland/configs/hypr/hypridle.conf;
    "hypr/hyprlock.conf".source = ../modules/desktop/hyprland/configs/hypr/hyprlock.conf;
    
    # Waybar configuration files
    "waybar/config".source = ../modules/desktop/hyprland/configs/waybar/config;
    "waybar/style.css".source = ../modules/desktop/hyprland/configs/waybar/style.css;
    
    # Wofi configuration files
    "wofi/config".source = ../modules/desktop/hyprland/configs/wofi/config;
    "wofi/style.css".source = ../modules/desktop/hyprland/configs/wofi/style.css;
  };
}
