# Productivity services configuration for Traefik
{lib, ...}: let
  tower = "192.168.1.240";
  bee = "localhost";
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
    public-site = {
      host = bee;
      port = 8888;
    }; # Bee service
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
