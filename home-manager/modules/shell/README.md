# Shell Configuration Strategy

## Overview

This repository uses a layered shell configuration approach:

1. **Bash** - System default shell for compatibility with scripts and automation
2. **Nushell** - Primary interactive shell for daily use

## Architecture

```
modules/shell/
├── common.nix      # Shell enhancement tools (zoxide, fzf, starship, eza, bat, atuin)
├── nushell.nix     # Core Nushell configuration (aliases, functions, settings, keybindings)
└── README.md       # This file
```

## Package Organization

### System-level (`modules/core/shell.nix`)
- Core shells: nushell
- Terminal tools: neovim, tmux

### Home-manager level (`modules/shell/`)
- Shell enhancements: atuin, starship, zoxide, fzf (in common.nix)
- Shell-specific tools: eza, bat (in common.nix)
- All configured with proper integrations for Nushell and Bash

## File Responsibilities

### common.nix
- Shell enhancement tool installations and configurations (atuin, zoxide, starship, fzf, eza, bat)
- Basic bash aliases for compatibility
- Tool integrations for both Bash and Nushell

### nushell.nix
- Core Nushell configuration
- Common aliases and functions used across all systems
- Custom keybindings (Ctrl+T for file search, Alt+C for directory change)
- Environment variables and startup scripts

## Import Hierarchy

```
profiles/base.nix (used by all hosts)
  → modules/shell/common.nix
    → modules/shell/nushell.nix
  → modules/atuin.nix

profiles/desktop.nix
  → profiles/base.nix

profiles/server.nix  
  → profiles/base.nix
```

## Key Functions & Keybindings

### Nushell Keybindings
- **Ctrl+T** - Fuzzy file search (insert file path at cursor)
- **Alt+C** - Fuzzy directory search (change to selected directory)
- **Ctrl+R** - Atuin smart history search (with sync across machines)

### Common Functions (all systems)
- `dot` - Navigate to dotfiles
- `dotc` - Navigate to dotfiles and launch Claude
- `tower` - SSH to tower (192.168.1.240)
- Docker helpers: `tdl`, `tdu`, `tdd`, `tdr`, `tde`
- Nix helpers: `run`, `shell`

### FZF Integration Functions
- `fuzzy_dir` / `fcd` - Fuzzy find and cd to directory
- `fuzzy_file` / `fv` - Fuzzy find and open file in nvim
- `gb` - Git branch switcher with fuzzy search
- `fkill` - Process killer with fuzzy search

### Local Aliases (defined in nushell.nix)
- `nr` - Quick local NixOS rebuild
- `modown` - Fix permissions for development

## Auto-launch Behavior

Bash is configured to automatically launch Nushell for interactive sessions (see `modules/core/shell.nix`).
This ensures compatibility with system scripts while providing a modern shell experience.