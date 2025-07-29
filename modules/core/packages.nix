# Core system packages for all hosts
# This module consolidates all system packages that should be available on every host

{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # === SHELLS & TERMINAL ===
    fish
    any-nix-shell # nix shell manager for fish
    
    # === MODERN CLI REPLACEMENTS ===
    # These tools have fish abbreviations defined in shell.nix
    eza # modern ls replacement
    bat # better cat with syntax highlighting
    fd # better find
    ripgrep # better grep
    tre-command # tree command, improved
    btop # modern top replacement
    dust # disk usage analyzer
    duf # disk free utility
    procs # process viewer
    sd # better sed
    dog # DNS lookup (better dig)
    hyperfine # benchmarking tool
    
    # === FILE NAVIGATION & SEARCH ===
    fzf # fuzzy finder
    nnn # terminal file manager
    broot # interactive tree navigator
    
    # === DEVELOPMENT TOOLS ===
    # Text Editors
    claude-code # AI-powered code assistant
    vim # text editor
    
    # Code Tools
    alejandra # nix formatter
    devenv # dev environment manager
    cht-sh # command cheatsheet
    glow # markdown previewer in terminal
    tokei # code line counter (cloc replacement)
    nodejs # JavaScript runtime (includes npm and npx)
    
    # === VERSION CONTROL ===
    # Git enhancements
    (writeShellScriptBin "jj" ''
      export JJ_CONFIG="/etc/jj/config.toml"
      exec ${jujutsu}/bin/jj "$@"
    '')
    delta # syntax-highlighting pager for git
    gh # GitHub CLI
    ghq # manage remote repository clones
    
    # === BASIC UTILITIES ===
    curl # HTTP client
    wget # file downloader
    jq # JSON processor
    
    # === NETWORK TOOLS ===
    # dig # DNS lookup (traditional) - use dog instead
    bind # includes nslookup
    
    # === FILE MANAGEMENT ===
    stow # symlink manager - use nix instead? that's what this new repo does for hyprland/waybar. consider switching back.
    inotify-tools # watch for file changes
    
    # === ARCHIVE MANAGEMENT ===
    p7zip # 7z file archiver
    unzip # extract ZIP archives
    zip # create ZIP archives
    
    # === SYSTEM MONITORING ===
    iftop # network monitoring
    iotop # I/O monitoring
    lm_sensors # hardware sensors
    neofetch # system information
    lsof # list open files
    
    # === SECRETS MANAGEMENT ===
    agenix-cli # age-encrypted secrets management CLI tool
  ];
}