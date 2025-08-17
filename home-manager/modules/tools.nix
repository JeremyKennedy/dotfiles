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