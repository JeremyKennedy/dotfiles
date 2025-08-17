# Nushell configuration - Primary shell for all users
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.nushell = {
    enable = true;
    
    # Main configuration
    configFile.text = ''
      # Load completions
      use ~/.cache/starship/init.nu
      
      # Minimal config - most defaults are fine
      $env.config = {
        show_banner: false
        
        # History is managed by Atuin - no need for built-in history config
        
        completions: {
          case_sensitive: false
          algorithm: "fuzzy"
        }
        
        buffer_editor: "nvim"
        edit_mode: vi  # Use vi key bindings
        
        keybindings: [
          {
            name: fuzzy_file_insert
            modifier: control
            keycode: char_t
            mode: [emacs, vi_normal, vi_insert]
            event: {
              send: executehostcommand
              cmd: "commandline edit --insert (fd --type f | fzf | str trim)"
            }
          }
          {
            name: fuzzy_directory_change
            modifier: alt
            keycode: char_c
            mode: [emacs, vi_normal, vi_insert]
            event: {
              send: executehostcommand
              cmd: "cd (fd --type d | fzf | str trim)"
            }
          }
          # Ctrl+R is handled by Atuin for much better history search
        ]
      }
      
      # Load zoxide
      source ~/.zoxide.nu
      
      # ===========================
      # ALIASES
      # ===========================
      # NOTE: Nushell aliases CANNOT:
      # - Chain multiple commands with ; or &&
      # - Change the current directory for the parent shell (use for simple cd only)
      # - Run complex logic (use 'def' functions instead)
      # For anything beyond simple command substitution, use 'def' to create a function
      
      # === NAVIGATION ===
      alias cd = z                    # Use zoxide for smart navigation
      alias cdi = zi                  # Interactive directory selection with zoxide
      alias .. = cd ..
      alias ... = cd ../..
      alias .... = cd ../../..
      
      # === FILE LISTING ===
      # Using Nushell's built-in ls for better table functionality and pipeline integration
      alias ll = ls -la  # Long format with hidden files using Nushell's built-in ls
      
      # === MODERN CLI REPLACEMENTS ===
      # These provide better versions of standard tools
      alias cat = bat                 # Syntax highlighting, line numbers
      alias find = fd                 # Faster, more intuitive than find
      alias grep = rg                 # Ripgrep: faster than grep
      alias tree = tre                # Better tree with git integration
      alias top = btop                # Beautiful resource monitor
      alias du = dust                 # Intuitive disk usage
      alias df = duf                  # Better disk free display
      alias ps = procs                # Modern process viewer
      alias sed = sd                  # Simpler find/replace than sed
      alias dig = dog                 # Colorful DNS client
      
      # === ESSENTIALS ===
      alias v = nvim
      alias g = git
      alias tower = ssh 192.168.1.240
      alias dot = cd ~/dotfiles
      # dotc runs claude in the dotfiles directory
      # Note: the directory change won't persist after claude exits
      def dotc [] { cd ~/dotfiles; claude }
      
      # === NIX ===
      # nr function is defined below in HELPER FUNCTIONS section
      
      # ===========================
      # HELPER FUNCTIONS
      # ===========================
      
      # Docker shortcuts for tower
      def tdl [container?: string] {
        if ($container | is-empty) {
          ssh 192.168.1.240 docker logs -f
        } else {
          ssh 192.168.1.240 docker logs -f $container
        }
      }
      
      def tdu [container: string] {
        ssh 192.168.1.240 docker start $container
      }
      
      def tdd [container: string] {
        ssh 192.168.1.240 docker stop $container
      }
      
      def tdr [container: string] {
        ssh 192.168.1.240 docker restart $container
      }
      
      def tde [container: string, ...args] {
        ssh 192.168.1.240 -t docker exec -it $container ...$args
      }
      
      # Nix helpers
      def run [package: string, ...args] {
        nix run $"nixpkgs#($package)" -- ...$args
      }
      
      def shell [...packages: string] {
        let pkg_args = $packages | each { |p| $"nixpkgs#($p)" } | str join " "
        nu -c $"nix shell ($pkg_args)"
      }
      
      # nr function moved to desktop.nix (desktop-only)
      
      # ===========================
      # FZF HELPERS
      # ===========================
      
      # File picker - find and cd to directory
      def fcd [] {
        let dir = (fd --type d | fzf)
        if ($dir | is-not-empty) {
          cd $dir
        }
      }
      
      # File opener - find and open file in editor
      def fv [] {
        let file = (fd --type f | fzf)
        if ($file | is-not-empty) {
          nvim $file
        }
      }
      
      # Git branch switcher
      def gb [] {
        let branch = (git branch -a | lines | str trim | fzf | str trim)
        if ($branch | is-not-empty) {
          git checkout ($branch | str replace "remotes/origin/" "" | str replace "* " "")
        }
      }
      
      # Process killer
      def fkill [] {
        let proc = (ps | fzf)
        if ($proc | is-not-empty) {
          kill ($proc | get pid | first)
        }
      }
      
      
      # ===========================
      # ENVIRONMENT
      # ===========================
      
      # Set default editor
      $env.EDITOR = "nvim"
      $env.VISUAL = "nvim"
    '';
    
    # Environment configuration
    envFile.text = ''
      # Directories to search for scripts when calling source or use
      $env.NU_LIB_DIRS = [
        ($nu.default-config-dir | path join 'scripts')
      ]
      
      # Directories to search for plugin binaries when calling register
      $env.NU_PLUGIN_DIRS = [
        ($nu.default-config-dir | path join 'plugins')
      ]
      
      # Initialize Starship
      mkdir ~/.cache/starship
      starship init nu | save -f ~/.cache/starship/init.nu
      
      # Initialize zoxide
      zoxide init nushell | save -f ~/.zoxide.nu
    '';
  };
}