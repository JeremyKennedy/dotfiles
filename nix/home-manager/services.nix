{
  config,
  pkgs,
  ...
}: {
  services = {
    nextcloud-client = {
      enable = true;
      startInBackground = true;
    };

    hypridle = {
      enable = true;
    };

    dunst = {
      enable = true;
    };
  };
}
