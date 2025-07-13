{
  pkgs,
  lib,
  ...
}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # Common aliases
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
}
