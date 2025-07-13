# Beelink Mini PC configuration for bee
{ config, pkgs, lib, ... }: {
  imports = [
    # Use server profile
    ../../profiles/server.nix
    
    # Host-specific
    ./disko.nix
    ./hardware-configuration.nix
    
    # Network services for this host
    ../../modules/services/dns/adguard.nix
    ../../modules/services/dns/coredns.nix
    ../../modules/services/web/traefik.nix
  ];
  
  networking.hostName = "bee";
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