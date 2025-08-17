# Common shell configuration for all users
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./nushell.nix
  ];

  # Shell-agnostic configuration
  programs = {
    # Better cd
    zoxide = {
      enable = true;
      enableNushellIntegration = true;
      enableBashIntegration = true;
    };

    # Starship prompt - use defaults
    starship = {
      enable = true;
      enableNushellIntegration = true;
      enableBashIntegration = true;
      # Use Starship's excellent defaults
    };

    # FZF for fuzzy finding - use defaults
    fzf = {
      enable = true;
      enableBashIntegration = true;
      # Note: Nushell integration for fzf is not available in home-manager
      # FZF still works in Nushell via the fzf binary
    };

    # eza removed - using Nushell's built-in ls instead

    # Better cat
    bat = {
      enable = true;
      config = {
        theme = "TwoDark";
        pager = "less -FR";
      };
    };
  };

  # Minimal bash aliases (most are in Nushell)
  # These are only for when using bash directly
  home.shellAliases = {
    # Modern replacements - same as Nushell for consistency
    cat = "bat";
    find = "fd";
    grep = "rg";
    # ls and ll use shell built-ins
  };
}