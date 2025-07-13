# Placeholder configuration for halo (VPS)
{ config, pkgs, lib, ... }: {
  networking.hostName = "halo";
  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = "x86_64-linux";
  
  # Minimal boot config (will be replaced with actual config)
  boot.loader.grub.device = "nodev";
  
  # Minimal filesystem config to make flake check pass
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
}