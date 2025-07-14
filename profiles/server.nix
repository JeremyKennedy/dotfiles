# Common server profile
{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../modules/core # Core modules for ALL hosts
  ];

  # Headless server - no GUI
  services.xserver.enable = lib.mkDefault false;

  # Automatic security updates
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    allowReboot = lib.mkDefault true;
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
}
