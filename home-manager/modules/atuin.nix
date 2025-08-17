# Atuin shell history configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    
    # Minimal settings - let atuin use its defaults for most things
    settings = {
      # Basic search settings
      search_mode = "fuzzy";
      filter_mode = "host";
      style = "compact";
      
      # Auto-execute selected command on Enter
      enter_accept = true;
      
      # Disable auto-sync by default
      auto_sync = false;
      update_check = false;
    };
  };

  # Setup Atuin key from age secret if available
  # Note: The actual age secret must be defined in the host's secrets.nix
  # This activation script runs after home-manager writes files
  home.activation.setupAtuin = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ATUIN_KEY_PATH="/run/agenix/atuin_key"
    
    # Only run if age secret exists
    if [ -f "$ATUIN_KEY_PATH" ]; then
      echo "Setting up Atuin sync key from age secret..."
      $DRY_RUN_CMD mkdir -p $HOME/.local/share/atuin
      $DRY_RUN_CMD cp "$ATUIN_KEY_PATH" $HOME/.local/share/atuin/key
      $DRY_RUN_CMD chmod 600 $HOME/.local/share/atuin/key
    else
      # Check if key already exists
      if [ ! -f "$HOME/.local/share/atuin/key" ]; then
        echo "No Atuin key found. To set up sync:"
        echo "  1. Run 'atuin login' on one machine"
        echo "  2. Copy the key from ~/.local/share/atuin/key"
        echo "  3. Create the age secret: echo 'KEY' | agenix -e secrets/atuin_key.age"
        echo "  4. Add to your host's secrets.nix"
      fi
    fi
  '';
}