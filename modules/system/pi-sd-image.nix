# Reusable module for building Raspberry Pi SD card images
{ config, lib, pkgs, modulesPath, ... }:

with lib;

{
  imports = [
    # Always import but conditionally enable
    "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
  ];

  options.pi-sd-image = {
    enable = mkEnableOption "Raspberry Pi SD card image building";
    
    imageBaseName = mkOption {
      type = types.str;
      default = config.networking.hostName or "nixos-pi";
      description = "Base name for the SD card image";
    };
  };

  config = mkIf config.pi-sd-image.enable {
    # SD image configuration
    sdImage = {
      imageBaseName = config.pi-sd-image.imageBaseName;
      compressImage = false;  # Skip compression for faster builds
    };
  };
}