{
  config,
  pkgs,
  ...
}: {
  # Enable networking
  networking = {
    hostName = "JeremyDesktop";
    networkmanager.enable = true;

    # Open ports in the firewall.
    firewall = {
      allowedTCPPorts = [
        3000 # dev server
        8080 # web host
        21 # ftp
      ];
      allowedTCPPortRanges = [
        {
          from = 51000;
          to = 51999;
        } # ftp
      ];
    };
  };

  # FTP server configuration
  services.vsftpd = {
    enable = true;
    writeEnable = true;
    localUsers = true;
    userlist = ["ftp"];
    userlistEnable = true;
    extraConfig = ''
      pasv_enable=Yes
      pasv_min_port=51000
      pasv_max_port=51999
    '';
  };

  # FTP user
  users.users.ftp = {
    isNormalUser = false;
    isSystemUser = true;
    home = "/home/ftp";
    group = "ftp";
    description = "FTP user";
  };

  # Enable OpenSSH daemon
  services.openssh = {
    enable = true;
    settings = {
      # Forbid root login through SSH.
      PermitRootLogin = "no";
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = false;
      # Disable interactive authentication
      KbdInteractiveAuthentication = false;
    };
    allowSFTP = true;
  };

  services.mullvad-vpn.enable = false;
}
