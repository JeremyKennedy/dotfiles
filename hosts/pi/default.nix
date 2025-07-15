# Raspberry Pi 4 configuration for pi
{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    # Use server profile
    ../../profiles/server.nix
    # Host-specific
    ./disko.nix
    ./network.nix
    # ./hardware-configuration.nix (not needed with disko)
  ];

  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = "aarch64-linux";

  # Raspberry Pi specific boot configuration - override common systemd-boot
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Disable documentation to avoid man-cache build issues during cross-compilation
  documentation.enable = false;
  documentation.man.enable = false;
}
