# Base home-manager profile for ALL hosts
# This provides common user environment across desktop and servers
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../modules/shell/common.nix
    ../modules/atuin.nix
    ../modules/git.nix
    ../modules/neovim.nix
    ../modules/tools.nix
  ];

  # Basic packages useful everywhere
  home.packages = with pkgs; [
    # System analysis
    killall
    
    # Cloud tools
    hcloud # Hetzner Cloud CLI
  ];

  # Basic home settings
  home = {
    # Session variables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
    };

    # Enable basic features
    enableNixpkgsReleaseCheck = false;
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}