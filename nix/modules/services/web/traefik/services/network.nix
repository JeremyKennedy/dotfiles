# Network services configuration for Traefik
#
# This module defines network infrastructure services.
# All services are internal-only for security.
#
# Internal services (accessible at service.home.jeremyk.net via Tailscale):
# - traefik: Reverse proxy dashboard (traefik.home.jeremyk.net) - hardcoded in default.nix
# - adguard: DNS filtering and ad blocking (adguard.home.jeremyk.net)
# - unifi: UniFi network controller (unifi.home.jeremyk.net)
#
{lib, ...}: let
  tower = "192.168.1.240"; # Unraid server
  bee = "localhost"; # Local host (bee)
in {
  # Network services organized by access level
  public = {};

  tailscale = {
    # Direct port access (unique ports)
    adguard = {
      host = bee;
      port = 3000; # Bee service - no conflicts
    };

    # SWAG proxy routing (port conflicts)
    unifi = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8443, conflicts with crafty and tower webui)
      https = true;
    };
  };
}
