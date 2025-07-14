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
      settings = {
        global = {
          origin = "top-right";
          monitor = 1;
          font = "JetBrainsMono Nerd Font 12";
        };
      };
    };
  };
}
