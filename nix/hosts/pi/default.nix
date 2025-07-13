# Placeholder configuration for pi (Raspberry Pi)
{ config, pkgs, lib, ... }: {
  networking.hostName = "pi";
  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = "aarch64-linux";
  
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