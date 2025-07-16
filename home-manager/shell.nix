# Navi-specific shell configuration
# Core shell configuration (shared by all hosts) is in ../modules/core/shell.nix
# This file adds navi desktop-specific customizations

{
  config,
  pkgs,
  ...
}: {
  programs = {
    # Fish configuration now in core - only add navi-specific abbreviations here
    fish = {
      enable = true;
      shellAbbrs = {
        # === NAVI-SPECIFIC SYSTEM SHORTCUTS ===
        nr = "cd ~/dotfiles && nix develop -c just rebuild"; # Local NixOS rebuild
        modown = "sudo chmod 777 -R . ; sudo chown -R jeremy:users . ; ll"; # Fix permissions (desktop use)
      };
    };

    alacritty = {
      enable = true;
      settings = {
        window = {
          # dimensions = {
          #   columns = 120;
          #   lines = 40;
          # };
          # opacity = 0.9;
          # decorations = "none";
        };
        env = {
          TERM = "xterm-256color";
        };
      };
    };

    # zellij = {
    #   enable = true;
    #   enableFishIntegration = true;
    # };

    # neovim, eza, fzf now configured in core modules
  };
}
