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
  inherit (import ../../../../core/hosts.nix) hosts;
  bee = "localhost"; # Local host (bee)
  navi = hosts.navi.tailscaleDomain;
  tower = hosts.tower.tailscaleDomain;
  halo = hosts.halo.tailscaleDomain;
in {
  # Network services organized by access level
  public = {};

  tailscale = {
    adguard = {
      host = bee;
      port = 3000;
    };
    unifi = {
      host = tower;
      port = 8443;
      https = true;
    };
  };
}
