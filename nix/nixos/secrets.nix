{config, ...}: {
  age.secrets = {
    hass_token = {
      file = ../secrets/hass_token.age;
      owner = "jeremy";
    };
    hass_server = {
      file = ../secrets/hass_server.age;
      owner = "jeremy";
    };
    chatgpt_key = {
      file = ../secrets/chatgpt_key.age;
      owner = "jeremy";
    };
    grist_api_key = {
      file = ../secrets/grist_api_key.age;
      owner = "grist-updater";
      group = "grist-updater";
    };
    grist_proxy_auth = {
      file = ../secrets/grist_proxy_auth.age;
      owner = "grist-updater";
      group = "grist-updater";
    };
  };
}
