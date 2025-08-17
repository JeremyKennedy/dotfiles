# Root user home-manager configuration for servers
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Use the server profile
    ./profiles/server.nix
  ];

  home = {
    username = "root";
    homeDirectory = "/root";
    stateVersion = "23.11";
  };
}