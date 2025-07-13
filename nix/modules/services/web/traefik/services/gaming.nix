# Gaming services configuration for Traefik
{lib, ...}: let
  tower = "192.168.1.240";
in {
  # Gaming services organized by access level
  public = {};

  tailscale = {
    crafty = {
      host = tower;
      port = 8443;
      https = true;
    };
  };
}
