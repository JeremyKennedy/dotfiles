# Helper functions for Traefik configuration
{lib}:
with lib; rec {
  # Helper to create a router configuration
  mkRouter = {
    name,
    config,
    public ? false,
  }: let
    subdomain = config.subdomain or name;
    service = config.service or name;
    extraHosts = config.extraHosts or [];
    hosts = ["${subdomain}.jeremyk.net"] ++ extraHosts;
    hostRule = concatMapStringsSep " || " (h: "Host(`${h}`)") hosts;
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

  # Helper to create a service configuration
  mkService = {
    name,
    config,
  }: let
    scheme =
      if config.https or false
      then "https"
      else "http";
    host = config.host;
    port = config.port;
    baseConfig = {
      loadBalancer = {
        servers = [{url = "${scheme}://${host}:${toString port}";}];
      };
    };
    backendConfig = config.backend or {};
  in
    recursiveUpdate baseConfig backendConfig;

  # Flatten services for processing
  flattenServices = services:
    foldl' (acc: category: acc // category.public // category.tailscale) {} (attrValues services);

  # Generate routers and backends from service definitions
  generateConfigs = services: let
    publicServices = foldl' (acc: cat: acc // cat.public) {} (attrValues services);
    tailscaleServices = foldl' (acc: cat: acc // cat.tailscale) {} (attrValues services);
    allServices = publicServices // tailscaleServices;

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

    # Filter out services that use internal Traefik services (like api@internal)
    servicesNeedingBackends =
      filterAttrs (
        n: c: let
          serviceName = c.service or n;
        in
          serviceName != "api@internal"
      )
      allServices;
    serviceBackends = mapAttrs (name: config: mkService {inherit name config;}) servicesNeedingBackends;
  in {
    routers = publicRouters // tailscaleRouters;
    services = serviceBackends;
  };
}
