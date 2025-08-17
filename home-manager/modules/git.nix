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
        syntax-theme = "gruvbox-dark";
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
        editor = "nvim";
      };
    };
  };
}