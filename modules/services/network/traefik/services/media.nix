# Media services configuration for Traefik
#
# This module defines media streaming and management services.
#
# Public services (accessible at service.jeremyk.net):
# - plex: Media streaming server
# - overseerr: Media request management
# - tautulli: Plex statistics
# - calibre-web: E-book library (books.jeremyk.net)
# - yourspotify: Spotify statistics
#
# Internal services (accessible at service.home.jeremyk.net via Tailscale):
# - sonarr, radarr, prowlarr: Media automation
# - bazarr: Subtitle management
# - deluge, nzbget: Download clients
# - tdarr: Media transcoding
# - calibre: E-book management
# - jackett: Torrent indexer proxy
#
{lib, ...}: let
  tower = "192.168.1.240"; # Unraid server
in {
  # Media services organized by access level
  public = {
    calibre-web = {
      host = tower;
      port = 6881;
      subdomain = "books";
    };
    overseerr = {
      host = tower;
      port = 5055;
      extraHosts = ["req.jeremyk.net" "request.jeremyk.net" "req.jibbs.stream" "request.jibbs.stream"];
    };
    plex = {
      host = tower;
      port = 32400;
      extraHosts = ["jibbs.stream"];
      middlewares = ["cors-allow-all"];
      backend = {
        loadBalancer.responseForwarding.flushInterval = "0s";
      };
    };
    yourspotify = {
      host = tower;
      port = 18803;
      https = true;
    };
  };

  tailscale = {
    bazarr = {
      host = tower;
      port = 6767;
    };
    deluge = {
      host = tower;
      port = 8112;
    };
    prowlarr = {
      host = tower;
      port = 9696;
    };
    radarr = {
      host = tower;
      port = 7878;
    };
    sonarr = {
      host = tower;
      port = 8989;
    };
    tdarr = {
      host = tower;
      port = 8265;
    };
    calibre = {
      host = tower;
      port = 6880;
    };
    nzbget = {
      host = tower;
      port = 6790;
    };
    tautulli = {
      host = tower;
      port = 8181;
    };
  };
}
