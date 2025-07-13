# Media services configuration for Traefik
{lib, ...}: let
  tower = "192.168.1.240";
in {
  # Media services organized by access level
  public = {
    plex = {
      host = tower;
      port = 32400;
      extraHosts = ["jibbs.stream"];
      middlewares = ["cors-allow-all"];
      backend = {
        passHostHeader = true;
        responseForwarding.flushInterval = "0s";
      };
    };
    overseerr = {
      host = tower;
      port = 5055;
      extraHosts = ["req.jeremyk.net" "request.jeremyk.net" "req.jibbs.stream" "request.jibbs.stream"];
    };
    tautulli = {
      host = tower;
      port = 8181;
    };
    "calibre-web" = {
      host = tower;
      port = 8083;
      subdomain = "books";
    };
    yourspotify = {
      host = tower;
      port = 3001;
    };
  };

  tailscale = {
    sonarr = {
      host = tower;
      port = 8989;
    };
    radarr = {
      host = tower;
      port = 7878;
    };
    prowlarr = {
      host = tower;
      port = 9696;
    };
    bazarr = {
      host = tower;
      port = 6767;
    };
    deluge = {
      host = tower;
      port = 8112;
    };
    nzbget = {
      host = tower;
      port = 6789;
    };
    tdarr = {
      host = tower;
      port = 8265;
    };
    calibre = {
      host = tower;
      port = 8080;
    };
    jackett = {
      host = tower;
      port = 9117;
    };
  };
}
