# Gaming services configuration for Traefik
#
# This module defines gaming-related services accessible through Traefik.
# All services in the tailscale section will be available at:
# service.home.jeremyk.net (internal access only via Tailscale)
#
{lib, ...}: let
  tower = "192.168.1.240"; # Unraid server
in {
  # Gaming services organized by access level
  public = {};

  tailscale = {
    # SWAG proxy routing (port conflicts)
    # crafty = {
    #   host = tower;
    #   port = 18071; # SWAG proxy HTTPS port (was 8443, conflicts with unifi)
    #   https = true;
    # };
  };
}
