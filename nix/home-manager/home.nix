{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./shell.nix
    ./packages.nix
    ./programs.nix
    ./services.nix
    ./hass-cli.nix
    ./chatgpt-cli.nix
  ];

  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 24;
  };

  home = {
    username = "jeremy";
    homeDirectory = "/home/jeremy";

    # This value determines the home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update home Manager without changing this value. See
    # the home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "23.11";
  };
}
