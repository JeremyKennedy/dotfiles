{
  config,
  pkgs,
  ...
}: {
  programs = {
    # Most programs moved to core modules
    # Keep only home-manager specific
    home-manager.enable = true;

    # programs to consider
    # firefox vscode
  };
}
