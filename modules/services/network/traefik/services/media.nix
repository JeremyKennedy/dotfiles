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
    "calibre-web" = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8083, port blocked)
      https = true;
      subdomain = "books";
    };
    overseerr = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 5055, service needs proxy)
      https = true;
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
      port = 18071; # SWAG proxy HTTPS port (was 3001, conflicts with gitea+kuma-tower)
      https = true;
    };
  };

  tailscale = {
    # Direct port access (unique ports)
    bazarr = {
      host = tower;
      port = 6767; # Direct port - no conflicts
    };
    deluge = {
      host = tower;
      port = 8112; # Direct port - no conflicts
    };
    prowlarr = {
      host = tower;
      port = 9696; # Direct port - no conflicts
    };
    radarr = {
      host = tower;
      port = 7878; # Direct port - no conflicts
    };
    sonarr = {
      host = tower;
      port = 8989; # Direct port - no conflicts
    };
    tdarr = {
      host = tower;
      port = 8265; # Direct port - no conflicts
    };

    # SWAG proxy routing (port conflicts or blocked)
    calibre = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8080, conflicts with microbin+scrutiny)
      https = true;
    };
    jackett = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 9117, port blocked)
      https = true;
    };
    nzbget = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 6789, service needs proxy)
      https = true;
    };
    tautulli = {
      host = tower;
      port = 18071; # SWAG proxy HTTPS port (was 8181, service needs proxy)
      https = true;
    };
  };
}
