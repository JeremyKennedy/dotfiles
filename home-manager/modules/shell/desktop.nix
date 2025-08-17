# Desktop-specific shell extensions
# These are additional functions and aliases for desktop/GUI environments
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.nushell.extraConfig = ''
    # ===========================
    # DESKTOP-SPECIFIC FUNCTIONS
    # ===========================
    
    # Quick local NixOS rebuild
    def nr [] {
      cd ~/dotfiles
      just rebuild
    }
    
    # Quick permissions fix for development
    def modown [] {
      sudo chmod 777 -R .
      sudo chown -R jeremy:users .
      ll
    }
    
    # Other desktop-specific functions can be added here
    # Examples:
    # - GUI app launchers
    # - Display/monitor management
    # - Clipboard operations
    # - Screenshot helpers
  '';
}