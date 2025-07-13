# Uptime Kuma monitoring service
#
# Access: http://halo.sole-bigeye.ts.net:3001
# Initial setup: Create admin account on first visit
#
# Features:
# - Service uptime monitoring
# - Multiple notification channels
# - Status pages
# - Docker container monitoring
# - SSL certificate monitoring
#
# Recommended monitors:
# - HTTP(s) monitors for all web services
# - TCP monitors for SSH (port 22)
# - DNS monitors for DNS services
# - Ping monitors for hosts
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
