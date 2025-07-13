# Host-specific networking configuration for navi
{
  config,
  pkgs,
  ...
}: {
  # Desktop-specific firewall rules
  networking.firewall = {
    allowedTCPPorts = [
      3000 # dev server
      8080 # web host
      21 # ftp
    ];
    allowedTCPPortRanges = [
      {
        from = 51000;
        to = 51999;
      } # ftp passive mode
    ];
  };

  # FTP server configuration (host-specific service)
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

  # Desktop doesn't need mullvad
  services.mullvad-vpn.enable = false;
}
