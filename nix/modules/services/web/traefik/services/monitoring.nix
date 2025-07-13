# Monitoring services configuration for Traefik
{lib, ...}: let
  tower = "192.168.1.240";
  bee = "localhost";
in {
  # Monitoring services organized by access level
  public = {
    kuma-tower = {
      host = tower;
      port = 3001;
      subdomain = "status";
      extraHosts = ["up.jeremyk.net"];
    };
    kuma-bee = {
      host = bee;
      port = 3001;
      subdomain = "status-bee";
    };
    librespeed = {
      host = tower;
      port = 80;
      subdomain = "speedtest";
    };
  };

  tailscale = {
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
