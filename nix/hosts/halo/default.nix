# VPS configuration for halo (ported from hetz-nix)
{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    # Use server profile
    ../../profiles/server.nix
    # Host-specific
    ./disko.nix
    ./hardware-configuration.nix
    # Services for this host
    ../../modules/services/monitoring/uptime-kuma.nix
  ];

  networking.hostName = "halo";
  system.stateVersion = "24.05";

  # Boot configuration (from hetz-nix) - override common systemd-boot
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false; # Required for efiInstallAsRemovable
    grub = {
      enable = true;
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };

  # Additional packages for VPS
  environment.systemPackages = with pkgs; [
    # VPS-specific packages can be added here
  ];

  # Enable IP forwarding for Tailscale exit node
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Firewall configuration
  # SECURITY: Services bind to 0.0.0.0 but are protected by firewall rules.
  # Only Tailscale traffic can reach them via trustedInterfaces.
  # Hetzner firewall provides additional protection at network level.
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"]; # Only trust Tailscale traffic
    checkReversePath = "loose"; # Required for exit nodes
    # No ports opened - tailscale0 trusted interface allows access
  };

  # Optimize network for Tailscale exit node performance
  systemd.services.tailscale-optimize-network = {
    description = "Optimize network settings for Tailscale";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on";
      RemainAfterExit = true;
    };
  };

  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
}
