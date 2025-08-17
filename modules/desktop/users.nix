# Desktop user configuration
{pkgs, ...}: {
  # Main desktop user account
  users.users.jeremy = {
    isNormalUser = true;
    description = "Jeremy";
    shell = pkgs.nushell;
    extraGroups = [
      "wheel" # Sudo access
      "ftp" # FTP access
      "adbusers" # Android debugging
      "docker" # Container management
    ];
  };

  # Desktop user needs to be trusted for nix commands
  nix.settings.trusted-users = ["root" "jeremy"];

  # Allow passwordless sudo for specific commands
  security.sudo.extraRules = [
    {
      users = ["jeremy"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/systemctl";
          options = ["NOPASSWD"];
        }
        {
          command = "/run/current-system/sw/bin/journalctl";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
