# Productivity services configuration for Traefik
#
# This module defines productivity and collaboration services.
#
# Public services (accessible at service.jeremyk.net):
# - nextcloud: File sync and collaboration (also cloud.jeremyk.net)
# - gitea: Git repository hosting
# - microbin: Pastebin service
# - immich: Photo management
# - mealie: Recipe manager
# - kutt: URL shortener
#
# Internal services (accessible at service.home.jeremyk.net via Tailscale):
# - paperless: Document management
# - grist: Spreadsheet database
# - kimai: Time tracking
# - overleaf: LaTeX editor
# - changes: Change tracking
# - homeassistant: Home automation (also hass/ha.home.jeremyk.net)
#
{lib, ...}: let
  inherit (import ../../../../core/hosts.nix) hosts;
  bee = "localhost"; # Local host (bee)
  navi = hosts.navi.tailscaleDomain;
  tower = hosts.tower.tailscaleDomain;
  halo = hosts.halo.tailscaleDomain;
in {
  # Productivity services organized by access level
  public = {
    # SWAG proxy routing (port conflicts or blocked)
    gitea = {
      host = tower;
      port = 3020; # SWAG proxy HTTPS port (was 3001, conflicts with kuma-tower+yourspotify)
    };
    kutt = {
      host = tower;
      port = 8180;
      subdomain = "link";
    };
    mealie = {
      host = tower;
      port = 3000;
    };
    microbin = {
      host = tower;
      port = 9647;
      subdomain = "bin";
    };
    nextcloud = {
      host = tower;
      port = 444;
      https = true;
      subdomain = "cloud";
      extraHosts = ["cloud.jeremyk.net"];
    };
  };

  tailscale = {
    changes = {
      host = tower;
      port = 5000;
    };
    grist = {
      host = tower;
      port = 8484;
    };
    home-assistant = {
      host = tower;
      port = 8123;
      subdomain = "hass";
      extraHosts = ["ha.home.jeremyk.net" "homeassistant.home.jeremyk.net"];
      middlewares = [];
    };
    immich = {
      host = tower;
      port = 2283;
    };
    kimai = {
      host = tower;
      port = 8092;
    };
    # overleaf = {
    #   host = tower;
    #   port = 80;
    # };
    paperless = {
      host = tower;
      port = 8102;
    };
    scoredo = {
      host = navi;
      port = 8000;
    };
    scoredo-db = {
      host = navi;
      port = 8003;
    };
  };
}
