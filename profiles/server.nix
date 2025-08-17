# Common server profile
{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    ../modules/core # Core modules for ALL hosts
    inputs.home-manager.nixosModules.home-manager
  ];

  # Home-manager configuration for servers
  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    users = {
      # Configure for root user on servers (since you SSH as root)
      root = import ../home-manager/root.nix;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

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
