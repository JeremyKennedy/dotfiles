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
  tower = "192.168.1.240";  # Unraid server
  bee = "localhost";        # Local host (bee)
  halo = "46.62.144.212";   # Hetzner VPS
in {
  # Monitoring services organized by access level
  public = {
    kuma-halo = {
      host = halo;
      port = 3001;
      subdomain = "uptime";
      extraHosts = ["status.jeremyk.net"];
    };
    librespeed = {
      host = tower;
      port = 80;
      subdomain = "speedtest";
    };
  };

  tailscale = {
    kuma-tower = {
      host = tower;
      port = 3001;
      subdomain = "uptime-tower";
      extraHosts = ["status-tower.home.jeremyk.net"];
    };
    grafana = {
      host = tower;
      port = 3000;
    };
    scrutiny = {
      host = tower;
      port = 8080;
    };
    teslamate = {
      host = tower;
      port = 4000;
    };
    "speedtest-tracker" = {
      host = tower;
      port = 8765;
      subdomain = "speedhist";
    };
  };
}
