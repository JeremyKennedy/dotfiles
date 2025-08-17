# Core system packages for all hosts
# This module consolidates all system packages that should be available on every host

{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # === SHELLS & TERMINAL ===
    # Moved to shell.nix: nushell, atuin
    
    # === MODERN CLI REPLACEMENTS ===
    bat # better cat with syntax highlighting
    btop # modern top replacement
    dog # DNS lookup (better dig)
    duf # disk free utility
    dust # disk usage analyzer
    # eza removed - using Nushell's built-in ls instead
    fd # better find
    hyperfine # benchmarking tool
    procs # process viewer
    ripgrep # better grep
    sd # better sed
    tre-command # tree command, improved
    
    # === FILE NAVIGATION & SEARCH ===
    # Moved to shell.nix: fzf, zoxide
    broot # interactive tree navigator
    nnn # terminal file manager
    
    # === DEVELOPMENT TOOLS ===
    # Text Editors
    claude-code # AI-powered code assistant
    # vim removed - using nvim with vim aliases instead
    
    # Code Tools
    alejandra # nix formatter
    cht-sh # command cheatsheet
    devenv # dev environment manager
    glow # markdown previewer in terminal
    just # command runner for project-specific tasks
    nodejs # JavaScript runtime (includes npm and npx)
    tokei # code line counter (cloc replacement)
    
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
    lsof # list open files
    neofetch # system information
    
    # === SECRETS MANAGEMENT ===
    agenix-cli # age-encrypted secrets management CLI tool
  ];
}