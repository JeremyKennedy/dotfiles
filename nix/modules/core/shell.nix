{
  pkgs,
  lib,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Common aliases (prefer abbreviations for better completion)
      alias g='git'
      alias v='nvim'
      alias ll='eza -la'
      alias la='eza -la'
      alias tree='tre'
      alias e='eza'

      # Nix shortcuts
      alias run='nix run nixpkgs#'
      alias shell='nix shell nixpkgs#'

      # System shortcuts
      alias nr='sudo nixos-rebuild switch'
      alias nru='sudo nixos-rebuild switch --upgrade'
      
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

  environment.systemPackages = with pkgs; [
    fish
    eza # modern ls replacement
    bat
    fd
    fzf # fuzzy finder
    ripgrep # search tool
    tre-command # tree command, improved
    alejandra # nix formatter
    cht-sh # command cheatsheet
    glow # markdown previewer in terminal
    any-nix-shell # nix shell manager for fish
    devenv # dev environment manager
  ];

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
