{
  config,
  pkgs,
  secrets,
  ...
}: {
  home.packages = [pkgs.chatgpt-cli];

  home.sessionVariables = {
    OPENAI_API_KEY = secrets.chatgpt.key;
  };
}
