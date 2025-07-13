# Desktop user configuration
{...}: {
  # Main desktop user account
  users.users.jeremy = {
    isNormalUser = true;
    description = "Jeremy";
    extraGroups = [
      "networkmanager" # Network management
      "wheel" # Sudo access
      "ftp" # FTP access
      "adbusers" # Android debugging
      "docker" # Container management
    ];
  };

  # Desktop user needs to be trusted for nix commands
  nix.settings.trusted-users = ["root" "jeremy"];
}
