# Beelink Mini PC configuration for bee
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Use server profile
    ../../profiles/server.nix

    # Host-specific
    ./disko.nix
    ./network.nix
    ./hardware-configuration.nix
    ./secrets.nix
    ./tailscale-override.nix

    # System modules
    ../../modules/system/debug-tools.nix

    # Services for this host
    ../../modules/services/network/adguard.nix
    ../../modules/services/network/traefik
    ../../modules/services/web/public-site.nix
    ../../modules/services/monitoring/netdata.nix
  ];

  system.stateVersion = "24.11";

  # Boot configuration for UEFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Additional packages for server management
  environment.systemPackages = with pkgs; [
    ethtool
  ];

  # Performance
  zramSwap.enable = true;

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}
