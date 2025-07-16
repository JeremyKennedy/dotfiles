# Core shell configuration for all hosts
# navi-specific customizations are in ../../home-manager/shell.nix
# This file provides base shell functionality that all hosts need

{
  pkgs,
  lib,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Safe aliases (always available for both interactive and scripts)
      alias g='git'
      alias v='nvim'
      alias tree='tre'
      
      # Nix shortcuts
      alias run='nix run nixpkgs#'
      alias shell='nix shell nixpkgs#'
      
      # System shortcuts
      alias nr='sudo nixos-rebuild switch'
      alias nru='sudo nixos-rebuild switch --upgrade'
      
      # Interactive-only configuration
      if status is-interactive
          # === NAVIGATION & DIRECTORY ===
          abbr --add cd z       # Use zoxide for smart navigation
          abbr --add cdi zi     # Interactive directory selection with zoxide
          
          # === FILE LISTING (eza replacements) ===
          abbr --add ls eza     # Replace ls with eza
          abbr --add l "eza -1" # Single column list
          abbr --add ll "eza -la" # Long format with hidden files
          abbr --add la "eza -a"  # Show hidden files
          abbr --add lt "eza -T"  # Tree view
          abbr --add llt "eza -laT" # Long format tree view
          
          # === MODERN CLI REPLACEMENTS ===
          abbr --add cat bat    # Syntax-highlighted cat
          abbr --add find fd    # Fast find alternative
          abbr --add grep rg    # Fast grep alternative
          abbr --add tree tre   # Modern tree command
          abbr --add top btop   # Modern top replacement
          abbr --add du dust    # Disk usage analyzer
          abbr --add df duf     # Disk free utility
          abbr --add ps procs   # Process viewer
          abbr --add sed sd     # Search and replace
          abbr --add dig dog    # DNS lookup
          abbr --add time hyperfine # Benchmarking tool
          
          # === DEVELOPMENT TOOLS ===
          abbr --add co "gh copilot" # GitHub Copilot CLI
          abbr --add ha hass-cli     # Home Assistant CLI
          
          # === SYSTEM SHORTCUTS ===
          # navi-specific shortcuts should be defined in home-manager/shell.nix
          
          # === SERVER MANAGEMENT ===
          # Note: These use the hosts configuration from hosts.nix
          # Tower server shortcuts
          abbr --add t "ssh 192.168.1.240 -t fish"
          abbr --add tower "ssh 192.168.1.240 -t fish"
          
          # Docker shortcuts for tower
          abbr --add tdl "ssh 192.168.1.240 docker logs -f"
          abbr --add tdu "ssh 192.168.1.240 docker start"
          abbr --add tdd "ssh 192.168.1.240 docker stop"
          abbr --add tdr "ssh 192.168.1.240 docker restart"
          abbr --add tde "ssh 192.168.1.240 -t docker exec -it"
      end

      # any-nix-shell integration
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
    '';
  };

  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
  programs.tmux.enable = true;
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Keep bash as root's shell to avoid breaking automation tools
  # But automatically start fish for interactive sessions
  programs.bash = {
    interactiveShellInit = ''
      # Automatically start fish for interactive sessions
      if [[ $- == *i* ]] && [[ -x ${pkgs.fish}/bin/fish ]]; then
        exec ${pkgs.fish}/bin/fish
      fi
    '';
  };

  # Shell-related packages are now in packages.nix

  # fzf configuration - good defaults for all users
  environment.etc."profile.d/fzf.sh".text = ''
    # fzf configuration
    export FZF_DEFAULT_COMMAND='${pkgs.ripgrep}/bin/rg --files --follow --hidden --glob "!.git/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='${pkgs.fd}/bin/fd --type d --hidden --follow --exclude .git'
    export FZF_DEFAULT_OPTS='
      --height 40%
      --layout=reverse
      --border
      --preview "${pkgs.bat}/bin/bat --style=numbers --color=always --line-range :500 {}"
      --preview-window right:50%
      --bind "ctrl-u:preview-page-up,ctrl-d:preview-page-down"
    '
  '';
}
