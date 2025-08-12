# Git configuration
{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    
    userName = "Jeremy Kennedy";
    userEmail = "me@jeremyk.net";
    
    # Delta provides nice diffs
    delta = {
      enable = true;
      options = {
        navigate = true;
        syntax-theme = "Catppuccin Mocha";  # Use the catppuccin theme from bat
        line-numbers = true;
        side-by-side = true;  # Show diffs side-by-side
        dark = true;
        plus-style = "syntax #2a2e3b";  # Catppuccin surface0 background
        minus-style = "syntax #2a2e3b";
      };
    };
    
    # Minimal config - use Git defaults for everything else
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;  # Rebase by default when pulling
      push.autoSetupRemote = true;  # Useful convenience
    };
  };
  
  # GitHub CLI
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };
  
  # Jujutsu (jj) - primary VCS
  programs.jujutsu = {
    enable = true;
    settings = {
      user = {
        name = "Jeremy Kennedy";
        email = "me@jeremyk.net";
      };
      ui = {
        default-command = "log";
        editor = "hx";  # Use helix instead of nvim
        diff-editor = ":builtin";  # Use jj's built-in diff editor (hx can't handle directories)
        pager = "delta";  # Use delta for paged output (diffs, logs, etc.)
        paginate = "auto";
      };
    };
  };
}