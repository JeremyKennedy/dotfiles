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
  bee = "localhost"; # Local host (bee)
  tower = "tower.sole-bigeye.ts.net"; # Unraid server
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
      port = 6580;
      subdomain = "speedtest";
    };
  };

  tailscale = {
    grafana = {
      host = tower;
      port = 3003;
    };
    kuma-tower = {
      host = tower;
      port = 3001;
    };
    scrutiny = {
      host = tower;
      port = 8088;
    };
    "speedtest-tracker" = {
      host = tower;
      port = 8094;
      subdomain = "speedhist";
    };
    teslamate = {
      host = tower;
      port = 4000;
    };
  };
}
