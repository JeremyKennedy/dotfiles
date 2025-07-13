# Common desktop profile - imports core modules plus desktop essentials
{ config, lib, pkgs, ... }: {
  imports = [
    ../modules/core      # Core modules for ALL hosts
    
    # Desktop modules would be imported by specific desktop hosts
    # as they may vary (Hyprland vs GNOME vs KDE, etc.)
  ];

  # Desktop-specific defaults
  services.xserver.enable = lib.mkDefault true;
  
  # Enable sound
  sound.enable = lib.mkDefault true;
  hardware.pulseaudio.enable = lib.mkDefault false;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
    alsa.support32Bit = lib.mkDefault true;
    pulse.enable = lib.mkDefault true;
  };

  # Enable networking GUI
  networking.networkmanager.enable = lib.mkDefault true;
  
  # Don't auto-upgrade desktops (user should control this)
  system.autoUpgrade.enable = lib.mkDefault false;
}