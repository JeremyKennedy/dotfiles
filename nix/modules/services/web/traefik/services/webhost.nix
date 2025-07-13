# Web hosting services configuration for Traefik
{lib, ...}: let
  bee = "localhost";
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
