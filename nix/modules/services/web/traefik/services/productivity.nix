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
  tower = "192.168.1.240";  # Unraid server
  bee = "localhost";        # Local host (bee)
in {
  # Productivity services organized by access level
  public = {
    nextcloud = {
      host = tower;
      port = 444;
      https = true;
      extraHosts = ["cloud.jeremyk.net"];
    };
    gitea = {
      host = tower;
      port = 3001;
    };
    microbin = {
      host = tower;
      port = 8080;
    };
    immich = {
      host = tower;
      port = 2283;
    };
    mealie = {
      host = tower;
      port = 9925;
    };
    kutt = {
      host = tower;
      port = 3000;
    };
  };

  tailscale = {
    paperless = {
      host = tower;
      port = 8010;
    };
    grist = {
      host = tower;
      port = 8484;
    };
    kimai = {
      host = tower;
      port = 8001;
    };
    overleaf = {
      host = tower;
      port = 80;
    };
    changes = {
      host = tower;
      port = 5000;
    };
    homeassistant = {
      host = tower;
      port = 8123;
      extraHosts = ["hass.jeremyk.net" "ha.jeremyk.net"];
      middlewares = ["websocket"];
    };
  };
}
