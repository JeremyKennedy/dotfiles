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
    ../common
    ./disko.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "halo";
  system.stateVersion = "24.05";

  # Boot configuration (from hetz-nix)
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # SSH brute force protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = ["100.64.0.0/10"]; # Tailscale network
  };

  # Additional packages for VPS
  environment.systemPackages = with pkgs; [
    claude-code
  ];

  # Uptime Kuma - NOT publicly exposed, bind to localhost only
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "127.0.0.1";  # Local only - access via Tailscale
      PORT = "3001";
    };
  };

  # Enable IP forwarding for Tailscale exit node
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Firewall configuration - minimal, Hetzner firewall handles main security
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose"; # Required for exit nodes
  };

  # Performance
  zramSwap.enable = true;

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

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}