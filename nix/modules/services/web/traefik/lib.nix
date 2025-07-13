# Helper functions for Traefik configuration
#
# This library provides functions to generate Traefik configuration from
# simplified service definitions. It handles the complexity of creating
# routers, services, and middleware configurations.
#
# Key concepts:
# - Router: Handles incoming requests and routes them to services based on rules (like domain names)
# - Service: Defines the backend servers that will handle the requests
# - Middleware: Modifies requests/responses (auth, headers, redirects, etc.)
#
{lib}:
with lib; rec {
  # Creates a Traefik router configuration
  # 
  # A router is what receives incoming HTTP requests and decides where to send them.
  # It matches requests based on rules (like "Host(`example.com`)") and forwards
  # them to a service. It can also apply middleware to modify the request/response.
  #
  # Inputs:
  #   name: Service name (used as default for subdomain if not specified)
  #   config: Service configuration containing:
  #     - subdomain: Subdomain for the service (default: service name)
  #     - service: Traefik service name to route to (default: service name)
  #     - extraHosts: Additional hostnames this service should respond to
  #     - middlewares: List of middleware names to apply
  #   public: Whether this service is publicly accessible (false = Tailscale only)
  #
  # Output: Traefik router configuration
  mkRouter = {
    name,
    config,
    public ? false,
  }: let
    subdomain = config.subdomain or name;
    service = config.service or name;
    extraHosts = config.extraHosts or [];
    # Handle root domain (empty subdomain)
    hosts = if subdomain == "" then ["jeremyk.net"] ++ extraHosts else ["${subdomain}.jeremyk.net"] ++ extraHosts;
    hostRule = concatMapStringsSep " || " (h: "Host(`${h}`)") hosts;
    # Always apply security headers, add tailscale-only for non-public services
    baseMiddlewares =
      ["security-headers"]
      ++ (
        if public
        then []
        else ["tailscale-only"]
      );
    serviceMiddlewares = config.middlewares or [];
  in {
    rule = hostRule;
    service = service;
    middlewares = baseMiddlewares ++ serviceMiddlewares;
    entryPoints = ["web" "websecure"];
    tls = {certResolver = "letsencrypt";};
  };

  # Creates a Traefik service (backend) configuration
  #
  # A service defines the actual backend servers that will handle requests.
  # It specifies the protocol (http/https), host, port, and any special
  # handling like load balancing or response modifications.
  #
  # Inputs:
  #   config: Service configuration containing:
  #     - host: Backend server hostname/IP
  #     - port: Backend server port
  #     - https: Whether to use HTTPS to connect to backend (default: false)
  #     - backend: Additional backend configuration (passHostHeader, etc.)
  #
  # Output: Traefik service configuration
  mkService = config: let
    scheme =
      if config.https or false
      then "https"
      else "http";
    host = config.host;
    port = config.port;
    baseConfig = {
      loadBalancer = {
        servers = [{url = "${scheme}\://${host}:${toString port}";}];
      };
    };
    backendConfig = config.backend or {};
  in
    recursiveUpdate baseConfig backendConfig;

  # Creates a redirect configuration
  #
  # This is a convenience function for creating services that only redirect
  # to other URLs without proxying to a backend.
  #
  # Inputs:
  #   name: Redirect name (used for subdomain)
  #   from: Source subdomain (e.g., "meet" for meet.jeremyk.net)
  #   to: Target URL to redirect to
  #   permanent: Whether this is a permanent (301) or temporary (302) redirect
  #
  # Output: Service configuration for a redirect
  mkRedirect = {
    name,
    from,
    to,
    permanent ? false,
  }: {
    subdomain = from;
    service = "noop@internal";  # Special Traefik service that does nothing
    middlewares = ["redirect-${name}"];
    # The middleware needs to be defined separately in the redirects service file
  };


  # Main function that generates all Traefik configurations from service definitions
  #
  # This function:
  # 1. Collects all services from category files
  # 2. Separates public and Tailscale-only services
  # 3. Creates routers for all services
  # 4. Creates backend configurations for services that need them
  # 5. Returns a complete Traefik dynamic configuration
  #
  # Input: Service definitions organized by category
  # Output: { routers = {...}; services = {...}; } for Traefik dynamic config
  generateConfigs = services: let
    # Separate public and tailscale services for different handling
    publicServices = foldl' (acc: cat: acc // cat.public) {} (attrValues services);
    tailscaleServices = foldl' (acc: cat: acc // cat.tailscale) {} (attrValues services);
    allServices = publicServices // tailscaleServices;

    # Create routers for all services
    publicRouters = mapAttrs (name: config:
      mkRouter {
        inherit name config;
        public = true;
      })
    publicServices;
    tailscaleRouters = mapAttrs (name: config:
      mkRouter {
        inherit name config;
        public = false;
      })
    tailscaleServices;

    # Only create backend services for those that need them
    # Skip internal Traefik services and redirects (which don't have host/port)
    servicesNeedingBackends =
      filterAttrs (
        n: c: let
          serviceName = c.service or n;
        in
          serviceName != "api@internal" && serviceName != "noop@internal" && c ? host && c ? port
      )
      allServices;
    serviceBackends = mapAttrs (name: config: mkService config) servicesNeedingBackends;
  in {
    routers = publicRouters // tailscaleRouters;
    services = serviceBackends;
  };
}