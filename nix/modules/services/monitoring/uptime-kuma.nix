# Uptime Kuma monitoring service
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Uptime Kuma - accessible via Tailscale only
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "0.0.0.0"; # Listen on all interfaces (firewall protects)
      PORT = "3001";
    };
  };

  # Open firewall port if enabled
  networking.firewall.allowedTCPPorts = [3001];
}
