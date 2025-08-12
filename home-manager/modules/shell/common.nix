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

    # Starship prompt with Catppuccin Mocha theme
    starship = {
      enable = true;
      enableNushellIntegration = true;
      enableBashIntegration = true;
      settings = {
        # Using Catppuccin Mocha palette
        # From: https://github.com/catppuccin/starship/blob/main/starship.toml
        palette = "catppuccin_mocha";
        
        palettes.catppuccin_mocha = {
          rosewater = "#f5e0dc";
          flamingo = "#f2cdcd";
          pink = "#f5c2e7";
          mauve = "#cba6f7";
          red = "#f38ba8";
          maroon = "#eba0ac";
          peach = "#fab387";
          yellow = "#f9e2af";
          green = "#a6e3a1";
          teal = "#94e2d5";
          sky = "#89dceb";
          sapphire = "#74c7ec";
          blue = "#89b4fa";
          lavender = "#b4befe";
          text = "#cdd6f4";
          subtext1 = "#bac2de";
          subtext0 = "#a6adc8";
          overlay2 = "#9399b2";
          overlay1 = "#7f849c";
          overlay0 = "#6c7086";
          surface2 = "#585b70";
          surface1 = "#45475a";
          surface0 = "#313244";
          base = "#1e1e2e";
          mantle = "#181825";
          crust = "#11111b";
        };
      };
    };

    # FZF for fuzzy finding with Catppuccin Mocha theme
    fzf = {
      enable = true;
      enableBashIntegration = true;
      # Note: Nushell integration for fzf is not available in home-manager
      # FZF still works in Nushell via the fzf binary
      
      # Catppuccin Mocha colors
      # From: https://github.com/catppuccin/fzf
      colors = {
        "bg+" = "#313244";
        bg = "#1e1e2e";
        spinner = "#f5e0dc";
        hl = "#f38ba8";
        fg = "#cdd6f4";
        header = "#f38ba8";
        info = "#cba6f7";
        pointer = "#f5e0dc";
        marker = "#f5e0dc";
        "fg+" = "#cdd6f4";
        prompt = "#cba6f7";
        "hl+" = "#f38ba8";
      };
    };

    # eza removed - using Nushell's built-in ls instead

    # Better cat
    bat = {
      enable = true;
      config = {
        theme = "Catppuccin Mocha";
        pager = "less -FR";
      };
      themes = {
        "Catppuccin Mocha" = {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "bat";
            rev = "d2bbee4f7e7d5bac63c054e4d8eca57954b31471";
            sha256 = "sha256-x1yqPCWuoBSx/cI94eA+AWwhiSA42cLNUOFJl7qjhmw=";
          };
          file = "themes/Catppuccin Mocha.tmTheme";
        };
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