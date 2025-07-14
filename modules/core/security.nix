# Common security configuration for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  # SSH brute force protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = [
      "100.64.0.0/10" # Tailscale network
      "127.0.0.1/8" # Localhost
    ];
    bantime = "10m";
  };

  # Basic firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    # Additional ports can be opened per-host as needed

    # Log dropped packets for debugging
    logRefusedConnections = false;
    logRefusedPackets = false;
    logRefusedUnicastsOnly = false;
  };
}
