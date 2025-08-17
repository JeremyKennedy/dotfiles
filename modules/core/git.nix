{pkgs, ...}: {
  # Git is now configured in home-manager for richer configuration
  # Just ensure it's available system-wide
  environment.systemPackages = with pkgs; [
    git
    git-lfs
  ];

  # Keep basic system git config for root operations
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";
      safe.directory = "*"; # Allow git operations in any directory
    };
  };
}
