# Web hosting services configuration for Traefik
#
# This module defines static website hosting services.
#
# Public services (accessible at service.jeremyk.net):
# - public-site: Main website (jeremyk.net and www.jeremyk.net)
#
{lib, ...}: let
  bee = "localhost";  # Local host (bee)
in {
  # Web hosting services organized by access level
  public = {
    public-site = {
      host = bee;
      port = 8888;
      subdomain = ""; # Root domain
      extraHosts = ["www.jeremyk.net"];
    };
  };

  tailscale = {};
}
