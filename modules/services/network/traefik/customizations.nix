# Reusable middleware definitions for Traefik
# Service-specific configurations are in their category files
{lib, ...}:
with lib; {
  # Reusable middleware definitions
  middleware = {
    # CORS headers - Allow cross-origin requests (use with caution)
    cors-allow-all = {
      headers = {
        accessControlAllowOriginList = ["*"];
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
