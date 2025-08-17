# Server home-manager profile
# Minimal - just imports base for common shell and tools
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./base.nix
  ];

  # Server-specific overrides
  home = {
    # No desktop packages on servers
    packages = with pkgs; [
      # Any server-specific CLI tools can go here
    ];
  };

  # Disable any desktop-specific services
  services = {
    # Ensure desktop services are disabled
    gpg-agent.enableSshSupport = lib.mkForce false; # Servers use system SSH agent
  };
}