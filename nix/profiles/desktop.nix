# Common desktop profile - imports core modules plus desktop essentials
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/core # Core modules for ALL hosts
    ../modules/desktop # Desktop modules (graphics, hyprland, waybar, ledger)
  ];

  # Desktop-specific defaults
  services.xserver.enable = lib.mkDefault true;

  # Enable sound with PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    jack.enable = true;
  };

  # Enable networking GUI
  networking.networkmanager.enable = lib.mkDefault true;

  # Don't auto-upgrade desktops (user should control this)
  system.autoUpgrade.enable = lib.mkDefault false;
}
