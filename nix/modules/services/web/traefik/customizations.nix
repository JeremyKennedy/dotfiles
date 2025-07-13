# Reusable middleware definitions for Traefik
# Service-specific configurations are in their category files
{lib, ...}:
with lib; {
  # Reusable middleware definitions
  middleware = {
    # WebSocket support - for any service that needs WebSocket connections
    websocket = {
      headers = {
        customRequestHeaders = {
          "Connection" = "upgrade";
          "Upgrade" = "websocket";
        };
      };
    };

    # LAN-only access
    lan-only = {
      ipWhiteList = {
        sourceRange = [
          "192.168.1.0/24" # Local network only
          "127.0.0.1/32"
          "::1/128"
        ];
      };
    };

    # CORS headers - Allow cross-origin requests (use with caution)
    cors-allow-all = {
      headers = {
        accessControlAllowOrigin = "*";
        accessControlAllowMethods = ["GET" "POST" "PUT" "DELETE" "OPTIONS"];
        accessControlAllowHeaders = ["*"];
      };
    };

    # Basic authentication prompt
    basic-auth = {
      basicAuth = {
        users = [
          # Users should be defined in secrets
          # Format: "username:hashedpassword"
        ];
      };
    };
  };
}
