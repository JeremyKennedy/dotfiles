# Common boot configuration for all hosts
{
  config,
  pkgs,
  lib,
  ...
}: {
  boot = {
    # Clean /tmp on boot (moved from base.nix for better organization)
    tmp.cleanOnBoot = true;

    # Default boot loader configuration
    # Hosts can override with mkForce if needed (e.g., GRUB for VPS)
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 10;
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
    };

    # Default to stable kernel packages
    # Desktop can override to latest, VPS can keep stable
    kernelPackages = lib.mkDefault pkgs.linuxPackages;
  };
}
