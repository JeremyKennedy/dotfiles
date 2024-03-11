{
  config,
  pkgs,
  secrets,
  ...
}: {
  home.packages = [pkgs.home-assistant-cli];

  home.sessionVariables = {
    HASS_TOKEN = secrets.hass.token;
    HASS_SERVER = secrets.hass.server;
  };
}
