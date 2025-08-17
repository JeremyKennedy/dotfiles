# Core shell configuration for all hosts
# Desktop-specific customizations are in home-manager/profiles/desktop.nix
# This file provides base shell functionality that all hosts need

{
  pkgs,
  lib,
  ...
}: {
  # Nushell is now the primary shell, configured in home-manager
  
  # Core shell packages - fundamental tools needed system-wide
  # Shell enhancements (atuin, starship, zoxide, fzf) moved to home-manager
  environment.systemPackages = with pkgs; [
    # Core shells
    nushell # modern structured data shell
    
    # Terminal tools
    neovim # editor (vim is in packages.nix)
    tmux # terminal multiplexer
  ];

  # Keep bash as the system shell for compatibility with scripts and automation
  # But automatically start nushell for interactive sessions
  programs.bash = {
    interactiveShellInit = ''
      # Automatically start nushell for interactive sessions
      if [[ $- == *i* ]] && [[ -x ${pkgs.nushell}/bin/nu ]]; then
        exec ${pkgs.nushell}/bin/nu
      fi
    '';
  };

  # Shell-related packages are in packages.nix
}