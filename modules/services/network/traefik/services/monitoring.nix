# Monitoring services configuration for Traefik
#
# This module defines monitoring and observability services.
#
# Public services (accessible at service.jeremyk.net):
# - kuma-halo: Uptime monitoring (uptime.jeremyk.net, status.jeremyk.net)
# - librespeed: Network speed testing (speedtest.jeremyk.net)
#
# Internal services (accessible at service.home.jeremyk.net via Tailscale):
# - kuma-tower: Tower uptime monitoring (uptime-tower.home.jeremyk.net, status-tower.home.jeremyk.net)
# - grafana: Metrics visualization
# - scrutiny: Hard drive health monitoring
# - teslamate: Tesla data logging
# - speedtest-tracker: Speed test history (speedhist.home.jeremyk.net)
#
{lib, ...}: let
  tower = "192.168.1.240"; # Unraid server
  bee = "localhost"; # Local host (bee)
  halo = "halo.sole-bigeye.ts.net"; # Hetzner VPS
in {
  # Monitoring services organized by access level
  public = {
    kuma-halo = {
      host = halo;
      port = 3001;
    };
    librespeed = {
      host = tower;
      port = 80; # Direct port - no conflicts (overleaf uses different access level)
      subdomain = "speedtest";
    };
  };

  tailscale = {
    # Direct port access (unique ports)
    teslamate = {
      host = tower;
      port = 4000; # Direct port - no conflicts
    };

    # SWAG proxy routing (port conflicts or blocked)
    grafana = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 3000, conflicts with mealie)
      https = true;
    };
    kuma-tower = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 3001, conflicts with gitea+yourspotify)
      https = true;
    };
    scrutiny = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8080, conflicts with calibre+microbin)
      https = true;
    };
    "speedtest-tracker" = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8765, port blocked)
      https = true;
      subdomain = "speedhist";
    };
  };
}
