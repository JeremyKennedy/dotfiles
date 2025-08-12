# Helix editor configuration
{ pkgs, ... }:
{
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_mocha";
    };
  };
}