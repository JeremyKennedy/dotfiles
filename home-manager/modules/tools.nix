# Development tools configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs = {
    # Terminal multiplexer - minimal config
    tmux = {
      enable = true;
      clock24 = true;
      baseIndex = 1;
      terminal = "screen-256color";
      
      # Just the essentials
      extraConfig = ''
        # Enable mouse support
        set -g mouse on
        
        # Increase history
        set -g history-limit 10000
      '';
    };
    
    # Directory environment management
    direnv = {
      enable = true;
      enableNushellIntegration = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;  # Re-enabled with .envrc in home to prevent errors
    };
    
    # Ripgrep configuration
    ripgrep = {
      enable = true;
      arguments = [
        "--max-columns=150"
        "--max-columns-preview"
        "--glob=!.git/*"
        "--glob=!node_modules/*"
        "--glob=!target/*"
        "--glob=!dist/*"
        "--glob=!.next/*"
        "--smart-case"
        "--hidden"
        "--follow"
      ];
    };
    
    # Better process viewer
    bottom = {
      enable = true;
      settings = {
        flags = {
          temperature_type = "c";
          rate = "1s";
        };
        colors = {
          # Catppuccin Mocha theme for btop/bottom
          # From: https://github.com/catppuccin/btop
          table_header_color = "#f5e0dc";
          all_cpu_color = "#f5c2e7";
          avg_cpu_color = "#cba6f7";
          cpu_core_colors = ["#f38ba8" "#eba0ac" "#fab387" "#f9e2af" "#a6e3a1" "#94e2d5" "#89dceb" "#74c7ec" "#89b4fa" "#b4befe"];
          ram_color = "#a6e3a1";
          swap_color = "#fab387";
          rx_color = "#89dceb";
          tx_color = "#f5c2e7";
          widget_title_color = "#cdd6f4";
          border_color = "#585b70";
          highlighted_border_color = "#f5c2e7";
          text_color = "#cdd6f4";
          graph_color = "#a6adc8";
          cursor_color = "#f5e0dc";
          selected_text_color = "#1e1e2e";
          selected_bg_color = "#b4befe";
          high_battery_color = "#a6e3a1";
          medium_battery_color = "#f9e2af";
          low_battery_color = "#f38ba8";
          gpu_core_colors = ["#89dceb" "#89b4fa" "#b4befe" "#cba6f7" "#f5c2e7" "#f2cdcd"];
          arc_color = "#94e2d5";
        };
      };
    };
    
    # GPG
    gpg = {
      enable = true;
      settings = {
        use-agent = true;
      };
    };
    
    # SSH
    ssh = {
      enable = true;
      compression = true;
      serverAliveInterval = 60;
      serverAliveCountMax = 3;
      extraConfig = ''
        # Reuse connections
        ControlMaster auto
        ControlPath ~/.ssh/control-%r@%h:%p
        ControlPersist 10m
        
        # Faster connections
        AddKeysToAgent yes
      '';
    };
    
    # Terminal file manager
    yazi = {
      enable = true;
      package = pkgs.yazi;
      # Changing working directory when exiting Yazi
      enableBashIntegration = true;
      enableNushellIntegration = true;
      settings = {
        mgr = {
          show_hidden = true;
          sort_dir_first = true;
        };
      };
      # Catppuccin Mocha theme
      # From: https://github.com/catppuccin/yazi
      theme = {
        flavor = {
          use = "mocha";
        };
        flavor.mocha = {
          identifier = {
            red = "#f38ba8";
            peach = "#fab387";
            yellow = "#f9e2af";
            green = "#a6e3a1";
            teal = "#94e2d5";
            blue = "#89b4fa";
            mauve = "#cba6f7";
            text = "#cdd6f4";
            subtext0 = "#a6adc8";
            subtext1 = "#bac2de";
          };
          base = "#1e1e2e";
          mantle = "#181825";
          crust = "#11111b";
          surface0 = "#313244";
          surface1 = "#45475a";
          surface2 = "#585b70";
          overlay0 = "#6c7086";
          overlay1 = "#7f849c";
          overlay2 = "#9399b2";
        };
      };
    };
  };
  
  # GPG agent
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    defaultCacheTtl = 7200;
    maxCacheTtl = 86400;
    pinentry.package = pkgs.pinentry-curses;
  };
}