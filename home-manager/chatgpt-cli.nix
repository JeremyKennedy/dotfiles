{
  config,
  pkgs,
  ...
}: {
  home.packages = [pkgs.chatgpt-cli];

  home.sessionVariables = {
    OPENAI_API_KEY = "$(cat /run/agenix/chatgpt_key 2>/dev/null || echo)";
  };
}
