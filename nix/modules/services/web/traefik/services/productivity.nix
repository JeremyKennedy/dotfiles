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
  tower = "192.168.1.240"; # Unraid server
  bee = "localhost"; # Local host (bee)
in {
  # Productivity services organized by access level
  public = {
    # SWAG proxy routing (port conflicts or blocked)
    gitea = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 3001, conflicts with kuma-tower+yourspotify)
      https = true;
    };
    kutt = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 3000, conflicts with grafana)
      https = true;
    };
    mealie = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 9925, port blocked)
      https = true;
    };
    microbin = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8080, conflicts with calibre+scrutiny)
      https = true;
    };
    nextcloud = {
      host = tower;
      port = 443; # SWAG proxy (was 444, service needs proxy)
      https = true;
      extraHosts = ["cloud.jeremyk.net"];
    };
  };

  tailscale = {
    # Direct port access (unique ports)
    changes = {
      host = tower;
      port = 5000; # Direct port - no conflicts
    };
    immich = {
      host = tower;
      port = 2283; # Direct port - no conflicts
    };
    home-assistant = {
      host = tower;
      port = 8123; # Direct port - Home Assistant accessible directly
      subdomain = "hass";
      extraHosts = ["ha.home.jeremyk.net" "homeassistant.home.jeremyk.net"];
      middlewares = [];
    };
    # overleaf = {
    #   host = tower;
    #   port = 80; # Direct port - no conflicts (librespeed conflict resolved via public/tailscale separation)
    # };

    # SWAG proxy routing (port conflicts or blocked)
    grist = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8484, service needs proxy)
      https = true;
    };
    kimai = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8001, port blocked)
      https = true;
    };
    paperless = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8010, port blocked)
      https = true;
    };
  };
}
