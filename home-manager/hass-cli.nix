{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.home-assistant-cli];

  home.sessionVariables = {
    HASS_TOKEN = "$(cat /run/agenix/hass_token 2>/dev/null || echo)";
    HASS_SERVER = "$(cat /run/agenix/hass_server 2>/dev/null || echo)";
  };
}
