# Netdata real-time monitoring service
#
# Access:
# - https://netdata-navi.home.jeremyk.net (desktop via Traefik)
# - https://netdata-bee.home.jeremyk.net (bee via Traefik)
# - https://netdata-halo.home.jeremyk.net (halo via Traefik)
# - https://netdata-tower.home.jeremyk.net (tower via Traefik)
# - http://HOST.sole-bigeye.ts.net:19999 (direct Tailscale)
# - http://HOST_IP:19999 (direct IP)
#
# Features:
# - Real-time system metrics (CPU, RAM, disk, network)
# - Interactive web dashboard
# - Historical data (in RAM by default)
# - Alerts and notifications
# - Low resource usage monitoring
# - Automatic service discovery
#
# Default configuration:
# - Listens on all interfaces (0.0.0.0:19999)
# - Data stored in RAM for performance
# - Minimal logging to reduce overhead
#
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Allow unfree package for netdata with Cloud UI
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "netdata"
  ];

  # Netdata - real-time monitoring accessible via Tailscale
  services.netdata = {
    enable = true;
    # Use newer maintained Cloud UI instead of broken old UI
    package = pkgs.netdata.override {
      withCloudUi = true;
    };
    config = {
      global = {
        "default port" = "19999";
        "bind socket to IP" = "0.0.0.0"; # Listen on all interfaces
        "memory mode" = "ram"; # Store data in RAM for performance
        "debug log" = "none"; # Minimal logging
        "access log" = "none";
        "error log" = "syslog";
      };
    };
  };

  # Open firewall port
  networking.firewall.allowedTCPPorts = [19999];
}