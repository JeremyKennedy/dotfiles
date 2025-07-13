# Network services configuration for Traefik
{lib, ...}: let
  tower = "192.168.1.240";
  bee = "localhost";
in {
  # Network services organized by access level
  public = {};

  tailscale = {
    adguard = {
      host = bee;
      port = 3000;
    }; # Bee service
    traefik-dashboard = {
      host = bee;
      port = 9090;
      service = "api@internal";
      subdomain = "traefik";
    }; # Bee service
    unifi = {
      host = tower;
      port = 8443;
      https = true;
    };
  };
}
