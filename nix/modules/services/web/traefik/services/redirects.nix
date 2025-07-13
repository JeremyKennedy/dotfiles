# Redirect services configuration for Traefik
{lib, ...}: {
  # Redirect services - these don't have backends
  public = {
    meet-redirect = {
      subdomain = "meet";
      service = "noop@internal";
      middlewares = ["meet-redirect-mw"];
    };
  };

  tailscale = {};

  # Redirect-specific middleware
  middleware = {
    meet-redirect-mw = {
      redirectRegex = {
        regex = "^https?://meet.jeremyk.net/(.*)";
        replacement = "https://meet.google.com/geq-fmkx-bde";
        permanent = false;
      };
    };
  };
}
